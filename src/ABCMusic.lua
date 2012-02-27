ABCMusic = class()
      
function ABCMusic:init(_ABCTune,LOOP,DEBUG,DUMP)
    self.DEBUG = DEBUG
    if self.DEBUG == nil then self.DEBUG = false end
    if DUMP == nil then DUMP = false end
    if _ABCTune == nil then
        print("No tune provided. Use ABCMusic(tunename)")
    end    
    self.LOOP = LOOP
    
    y=0
   -- watch("self.tempo")
    --watch("framesToBeSkipped")
    self.soundTablePointer=1
    
    self.soundTable = {}
    
    self.timeElapsedSinceLastNote = 0

    self.duration = 1
    gnDurationSeconds = 0
    --tempDuration = 1
    self.tempo = 240 -- if no tempo is specified in the file, use this
    self.noteLength = (1/8) -- if no default note length is specified in the file, use this
    
    -- This is the cycle of fifths.  It helps us figure out which accidentals to use
    -- for a given key.
    cycleOfFifths = {"Cb","Gb","Db","Ab","Eb","Bb","F",
    "C","G","D","A","E","B","F#","C#","G#","D#","A#"}
      
    -- This is the amount you need to multiply a note value by to get the next highest one.
    -- Don't ask me why it's not in hertz, it hurts.
    multiplier = 1.0296
    pitchTable = {1} -- This table will be filled with the note values
    pitch = pitchTable[1]
    self.semitoneModifier = 0
    
    gsNoteOrder = "CDEFGABcdefgab"
    gsTonalSystem = "22122212212221" -- compared with the noteOrder, this shows the no of 
                                  --  semitones between each note, like the black and white keys.
   
    -- There are 88 keys on a piano, so we will start from our highest note and go down.
    -- We calculate the notes ourselves and put them in a table. 
    for i = 88, 1, -1 do
        pitch = pitch / multiplier
        table.insert(pitchTable,1,pitch)
    end
    --print(table.concat(pitchTable,"\n"))
        
    -- These are the 'Guitar chords' and the notes making up each one.
    -- Further work needed to expand the range of chords known.
    chordList = {
    ["C"]={"C","E","G"},
    ["C7"]={"C","E","G","^A"},
    ["D"]={"D","^F","A"},
    ["D7"]={"D","^F","A","c"},
    ["Dm"]={"D","F","A"},
    ["Dm7"]={"D","F","A","c"},
    ["E"]={"E","^G","B"},
    ["Em"]={"E","G","B"},
    ["F"]={"F","A","c"},
    ["G"]={"G","B","D"},
    ["G7"]={"G","B","D","F"},
    ["A"]={"A","^C","E"},
    ["Am"]={"A","C","E"},
    ["Am7"]={"A","C","E","G"},
    ["Bb"]={"_B","D","F"},
    ["Bm"]={"B","D","^F"}}
    
    
      
    -- Print the raw ABC tune for debugging
    if DEBUG then print(_ABCtune) end
    
    -- This is a table of patterns that we use to match against the ABC tune.
    -- We use these to find the next, biggest meaningful bit of the tune.
    -- Lua patterns is like RegEx, in that we can specify parts of the match to be captured with
    -- sets of parentheses.
    -- Not all tokens have been implemented yet, but at least we understand
    -- musically what is going on.
    tokenList = {
        TOKEN_REFERENCE = "^X:%s?(.-)\n",
        TOKEN_TITLE = "^T:%s?(.-)\n",
        TOKEN_COMMENT = "%%.-\n",
        TOKEN_KEY = "%[?K:%s?(%a[b#]?)%s?(%a*)[%]\n]", -- matches optional inline [K:...]
        TOKEN_METRE = "%[?M:%s?(.-)[%]\n]",
        TOKEN_DEFAULT_NOTE_LENGTH = "%[?L:%s?(%d-)%/(%d-)[%]\n]",
        TOKEN_TEMPO = "%[?Q:%s?(%d*%/?%d*)%s?=?%s?(%d*)[%]\n]", -- matches deprecated, see standard
        TOKEN_CHORD_DURATION = '%[([%^_=]?[a-gA-G][,\']?[,\']?[,\']?%d*/?%d?.-)%]',
        TOKEN_GUITAR_CHORD = '"(%a+%d?)"',
        TOKEN_START_REPEAT = '|:',
        TOKEN_END_REPEAT = ':|',
        TOKEN_END_REPEAT_START = ":|?:",
        TOKEN_NUMBERED_REPEAT_START = "[|%[]%d",
        TOKEN_NOTE_DURATION = '([%^_=]?[a-gA-G][,\']?[,\']?[,\']?)(%d*/?%d?)',
        TOKEN_PREV_DOTTED_NEXT_HALVED = ">",
        TOKEN_PREV_HALVED_NEXT_DOTTED = "<",
        TOKEN_SPACE = "%s",
        TOKEN_BARLINE = "|",
        TOKEN_DOUBLE_BARLINE = "||",
        TOKEN_THIN_THICK_BARLINE = "|%]",
        TOKEN_NEWLINE = "\n",
        --TOKEN_DOUBLE_FLAT = "__",
        --TOKEN_DOUBLE_SHARP = "%^^",
        TOKEN_ACCIDENTAL = "([_=\^])",
        TOKEN_REST_DURATION = "(z)(%d?/?%d?)",
        TOKEN_REST_MULTIMEASURE = "(Z)(%d?)",
        TOKEN_TRILL = "~",
        TOKEN_START_SLUR = "%(",
        TOKEN_END_SLUR = "%)",
        TOKEN_STACATO = "%.",
        TOKEN_TUPLET = "%(([1-9])([%^_=]?[a-gA-G][,']?[,\']?[,\']?[%^_=]?[a-gA-G]?[,']?[,\']?[,\']?[%^_=]?[a-gA-G]?[,']?[,\']?[,\']?)",
        TOKEN_TUPLET_INDICATOR = "%(([1-9]):?([1-9]?):?([1-9]?)",
        TOKEN_TIE = "([%^_=]?[a-gA-G][,\']?[,\']?[,\']?)%d?/?%d?%-.*(%1%d?/?%d?)",
        TOKEN_MISC_FIELD = "^[(ABCDEFGHIJNOPRSUVWYZmrsw)]:(.-)\n"} -- no overlap with 
                                                -- already specified fields like METRE or KEY

    self:parseTune(_ABCTune)
    self:createSoundTable()
    if DUMP then
        dump(self.soundTable) -- for debugging
    end
end


function ABCMusic:parseTune(destructableABCtune)
    
    self.destructableABCtune = destructableABCtune
    -- Go through each token and find the first match in the tune.  Use the biggest lowest
    -- starting index and then discard the characters that matched.
    
    local lastLongest = 0
    self.parsedTune = {}
    
    -- We create a copy of the tune to whittle away at.
    --destructableABCtune = ABCtune
    local lastToken
    local lastTokenMatch
    local captureFinal1
    local captureFinal2
    
    -- Iterate through the tune until none left
    while true do
        
        -- Loop through all tokens to see which one matches the start of the whittled tune.
        for key, value in pairs(tokenList) do
            
            local token = value
            -- Find the start and end index of the token match, plus record what was in the 
            -- pattern capture parentheses.  I pulled out a max two captures for each match, which
            -- seemed adequate.
            local startIndex
            local endIndex
            local capture1
            local capture2
           
            
            startIndex, endIndex, capture1, capture2 = string.find(self.destructableABCtune, token)
            if startIndex == nil then startIndex = 0 end
            if endIndex == nil then endIndex = 0 end
            -- Get the actual match from the tune
            local tokenMatch = string.sub(self.destructableABCtune,startIndex, endIndex)
        
            -- Take the one that matches the start of the whittled tune.
            if startIndex == 1 then
                
                -- In case there are two possible matches, then take the biggest one.    
                -- This shouldn't happen if the token patterns are right.
                if endIndex > lastLongest then
                   
                    lastLongest = endIndex
                    lastToken = key
                    lastTokenMatch = tokenMatch
                    captureFinal1 = capture1
                    captureFinal2 = capture2
                end
            end
        end
        
        if lastTokenMatch == "" then
            print("No match found for character ".. string.sub(self.destructableABCtune,1,1) )
            print("Remaining characters: ".. #self.destructableABCtune)
            -- set the whittler to trim the strange character away
            lastLongest = 1
        else
            -- Build a table containing the parsed tune.
            -- Due to iterative delays in the print function needed for debugging, we will use
            -- a 4-strided list for quicker printing it later with table.concat().
            table.insert(self.parsedTune,lastToken)
            table.insert(self.parsedTune,lastTokenMatch)
            
            -- Where no captures occurred, we will just fill the table item with 1,
            -- which will be the default duration of a note that has no length modifier.
            if captureFinal1 == "" or captureFinal1 == nil then captureFinal1 = 1 end
            if captureFinal2 == "" or captureFinal2 == nil then captureFinal2 = 1 end
            
            table.insert(self.parsedTune,captureFinal1)
            table.insert(self.parsedTune,captureFinal2)
        end
        
        -- Whittle off the match
        self.destructableABCtune = string.sub(self.destructableABCtune, lastLongest + 1)
        
        -- Stop the loop once we have no tune left to parse
        if string.len(self.destructableABCtune) == 0 then
            break
        end
         
        -- Clear the variables       
        lastLongest = 0
        lastToken = ""
        lastTokenMatch = ""
    end
    
    -- Go back over the tune to replace ties within chords with their proper durations
    -- Find next chord with tie and the following note that matches the tied note
    local pointer = 1
    local note
    local dur
    local nextRawMatch
    local endTieNoteStart
    local endTieNoteEnd
    local endTieDur
    
    while pointer <= #self.parsedTune do
        
        if self.parsedTune[pointer] == "TOKEN_CHORD_DURATION" then
            
            local rawMatch = self.parsedTune[pointer + 1]
            
            local tiePos = string.find(rawMatch,"-")
            
            if tiePos ~= nil then
                note, dur = string.match(rawMatch,tokenList["TOKEN_NOTE_DURATION"].."-")
                --print("Note is ".. note)
                if dur == nil or dur == "" then dur = 1 end
               --print("dur is "..dur)
               -- print("fund tie chord " .. rawMatch)
                
                -- Look ahead
                local nextPointer = pointer
                while nextPointer <= #self.parsedTune do
                   -- print("skipping alog")
                    nextPointer = nextPointer + 4
                    if self.parsedTune[nextPointer] == "TOKEN_NOTE_DURATION" then
                local endTieNote = self.parsedTune[nextPointer + 2]
                local endTieDur = self.parsedTune[nextPointer + 3]
                  --  print("found next note")
                    
                        if note == endTieNote then
                           -- print("matched next chord with tie")
                                -- delete that record
                                local z
                                for z = 1, 4 do
                                    
                                    table.remove(self.parsedTune,nextPointer)
                                end
                                
                                break
                        end
                       
                    end
                    if self.parsedTune[nextPointer] == "TOKEN_CHORD_DURATION" then
                        
                        local notePattern = note .. '[_%^=]?(%d*/?%d?)'
    
                        nextRawMatch = self.parsedTune[nextPointer + 1]
                     
                        
                        endTieNoteStart, endTieNoteEnd, endTieDur = string.find(nextRawMatch, notePattern)
                        if endTieDur == nil or endTieDur == ""then endTieDur = 1 end
                   end
                    
                    if endTieNoteStart ~= nil then
                        -- delete that bit
                        nextRawMatch = string.sub(nextRawMatch,1,endTieNoteStart-1)..
                            string.sub(nextRawMatch,endTieNoteEnd+1)
                        self.parsedTune[nextPointer + 1] = nextRawMatch
                   
                        endTieNoteStart = nil
                        pointer = pointer + 4
                        break
                    end
                    
                end
                -- add durations
                dur = tonumber(dur) + tonumber(endTieDur)
                -- replace the - with a duration made from the sum of the first and second notes
                rawMatch = string.sub(rawMatch,1,tiePos-1)..dur..
                            string.sub(rawMatch,tiePos+1)
                        self.parsedTune[(pointer - 4)+ 1] = rawMatch
                    
            end
        end
        
        pointer = pointer + 4
    end
    
    -- For debugging purposes, print the whole parsed tune.
    if self.DEBUG then print(table.concat(self.parsedTune,"\n")) end
end


function ABCMusic:createSoundTable()
    -- Here we interpret the parsed tune into a table of notes to play and for how long.
    -- The upside of an intermediate process is that there will be no parsing delays to lag
    -- things if we are playing music in the middle of a game.  It is also easier to debug!
    -- On the other hand, ABC format allows for inline tempo or metre changes. To comply
    -- we would need to either switch duration to seconds rather than beats, or implement another
    -- parsing thing during playback...
    
    local duration
    local tempChord={}
    local parsedTunePointer = 1
    while true do
        
        if self.parsedTune[parsedTunePointer] == nil then break end
        
        -- Break out our 4-strided list into the token, what it actually matched, and the
        -- two captured values.
        token = self.parsedTune[parsedTunePointer]
        rawMatch = self.parsedTune[parsedTunePointer + 1]
        value1 = self.parsedTune[parsedTunePointer + 2]
        value2 = self.parsedTune[parsedTunePointer + 3]
        
        -- Doing anything here seems to take forever.
        -- print(token.."\n"..rawMatch.."\n"..value1.."\n"..value2) end
    
        -- this is so cool: setting the key sig
        if token == "TOKEN_KEY" then
            
            if value2 == 1 then
                self.mode = "major"
            else
                self.mode = value2
            end
            
            -- search cycle for marching tonic.
            for i = 1, #cycleOfFifths do
           
                if cycleOfFifths[i] == value1 then
                    cycleOfFifthsIndex = i
                    break
                end
            
            end
            
            if self.DEBUG then print("index of key of cycle is "..cycleOfFifthsIndex) end
            if self.DEBUG then print("mode is "..self.mode) end
            
            self.accidentals = ""
            
            if cycleOfFifthsIndex~= nil then
                
                if self.mode == "minor" then 
                    cycleOfFifthsIndex = cycleOfFifthsIndex - 3 
                end
                    
                    if cycleOfFifthsIndex > 8 then -- if on the right hand side of circle
                        for x = 7, (cycleOfFifthsIndex - 2) do
                            self.accidentals = self.accidentals .. cycleOfFifths[x]
                        end 
                    end
                    -- if the key is C major or A minor, the centre of the cycle, 
                    -- no accidentals are needed.
                    if cycleOfFifthsIndex < 8 then -- if on the left hand side of circle
                        for x = 6, (cycleOfFifthsIndex - 1), -1 do
                            self.accidentals = self.accidentals .. cycleOfFifths[x]
                        end 
                    end
             
                if self.DEBUG then print("Looking for these sharps: " .. self.accidentals) end
            end
        end
    
        if token == "TOKEN_TEMPO" then
            if string.find(value1,"/") then
                self.tempo = tonumber(value2)
            else
                self.tempo = tonumber(value1)
                self.tempoIsSingleFigure = true -- This is deprecated in the ABC standard
            end
            if self.DEBUG then print("Tempo found at: " .. self.tempo) end 
          -- iparameter("ptempo", 40, 480, self.tempo)
        end
        
        if token == "TOKEN_DEFAULT_NOTE_LENGTH" then
            noteLength = value2
            -- Set the tempo, eg if you wanted one quarter note or crotchet per second
            -- you would set Q:60 and L:1/4
            if self.tempoIsSingleFigure == true then         
                self.tempo = self.tempo * (noteLength/4)
            end
            if self.DEBUG then print("internal Tempo is " .. self.tempo) end
        end
        
    
        if token == "TOKEN_NOTE_DURATION" then
            duration = value2
            -- because the ABC standard allows /4 to mean 1/4, we fix that here
            if string.sub(duration,1,1) == "/" then
                duration = "1"..duration 
                
            end
            if duration == "1/" then
                duration = "1/2"
            end
                        
            if string.find(duration, "/") ~= nil then
          
                local numerator = tonumber(string.sub(duration,1,string.find(duration,"/")-1))
                local denominator = tonumber(string.sub(duration,string.find(duration,"/")+1))
            
                duration = numerator / denominator
            end

              -- hack for key signature
            
                firstChar = string.upper(string.sub(value1,1,1))
                if firstChar ~= "^" and firstChar ~= "_" then
                    if string.find(self.accidentals,firstChar) ~= nil then 
                        if cycleOfFifthsIndex > 8 then
                            value1 = "^" .. value1
                          
                        end
                        if cycleOfFifthsIndex < 8 then
                            value1 = "_" .. value1
                      
                        end
                    
                    end
                end
            
            if firstChar == "=" then
                value1 = string.sub(value1,2)
            end
            
             -- If there are chords to play at the same time, they will be in the tempChord table.      
            table.insert(tempChord,{ABCMusic:convertNoteToPitch(value1), ABCMusic:convertDurationToSeconds(duration,self.tempo)})
            table.insert(self.soundTable,tempChord)
            tempChord = {}
        end 
        
        if token == "TOKEN_REST_DURATION" then
            duration = value2
            if string.sub(duration,1,1) == "/" then
                duration = "1"..duration 
            end
            
            if string.find(duration, "/") ~= nil then
          
                local numerator = tonumber(string.sub(duration,1,string.find(duration,"/")-1))
                local denominator = tonumber(string.sub(duration,string.find(duration,"/")+1))
            
                duration = numerator / denominator
            end
            
            duration = tonumber(duration)
    table.insert(self.soundTable,{{"z", ABCMusic:convertDurationToSeconds(duration,self.tempo)}})
        end 
        
        if token == "TOKEN_TIE" then
            value1, duration1 = string.match(value1,tokenList["TOKEN_NOTE_DURATION"])
            value2, duration2 = string.match(value2,tokenList["TOKEN_NOTE_DURATION"])
            
           if self.DEBUG then print("val1 " .. value1.. " value2 ".. value2) end
            
            if string.sub(duration1,1,1) == "/" then
                duration1 = "1"..duration1 
             
            end
       
            if string.find(duration1, "/") ~= nil then
            
                local numerator = tonumber(string.sub(duration1,1,string.find(duration1,"/")-1))
                local denominator = tonumber(string.sub(duration1,string.find(duration1,"/")+1))
            
                duration1 = numerator / denominator
            end
            
            if string.sub(duration2,1,1) == "/" then
                duration2 = "1"..duration2 
           
            end
     
            if string.find(duration2, "/") ~= nil then
            
                local numerator = tonumber(string.sub(duration2,1,string.find(duration2,"/")-1))
                local denominator = tonumber(string.sub(duration2,string.find(duration2,"/")+1))
            
                duration2 = numerator / denominator
            end

            if duration1 == nil or duration1 == "" then duration1 = 1 end
            if duration2 == nil or duration2 == "" then duration2 = 1 end
            
            if self.DEBUG then print("dur1 ".. duration1 .. "dur2 ".. duration2) end

            duration = tonumber(duration1) + tonumber(duration2)
            table.insert(self.soundTable,{{ABCMusic:convertNoteToPitch(value1), ABCMusic:convertDurationToSeconds(duration,self.tempo)}})
        end
        
        if token == "TOKEN_TUPLET" then
            -- More types of tuplets exist, up to 9, but need more work.
            if value1 == "2" then
                duration = 1.5 -- the 2 signals two notes in the space of three
                -- We reprocess the notes making up the tuplet
                for i = 1, string.len(value2) do
                    note,noteLength = string.match(value2,tokenList["TOKEN_NOTE_DURATION"],i)
                    table.insert(self.soundTable,{{ABCMusic:convertNoteToPitch(note), ABCMusic:convertDurationToSeconds(duration,self.tempo)}})
                end
            end  
            
            if value1 == "3" then
                duration = 1/3 -- the 3 signals three notes in the space of two
                -- We reprocess the notes making up the tuplet
                for i = 1, string.len(value2) do
                    note,noteLength = string.match(value2,tokenList["TOKEN_NOTE_DURATION"],i)
                    table.insert(self.soundTable,{{ABCMusic:convertNoteToPitch(note), ABCMusic:convertDurationToSeconds(duration, self.tempo)}})
                end
            end            
        end
        
        if token == "TOKEN_GUITAR_CHORD" then
            -- The ABC standard leaves it up to the software how to interpret guitar chords,
            -- but they should precede notes in the ABC tune.  I'm just going with a vamp.
            duration = 1
            self.tempChord = {}
            if chordList[value1] == nil then
               print("Chord ".. value1.. " not found in chord table.")
            else
                for key, value in pairs(chordList[value1]) do
                    -- This places the notes of the chord into a temporary table which will
                    -- be appended to by the next non-chord note.
                    table.insert(self.tempChord,{ABCMusic:convertNoteToPitch(value1), ABCMusic:convertDurationToSeconds(duration, self.tempo)})
                end        
            end         
        end
        
        if token == "TOKEN_CHORD_DURATION" then
            -- These are arbitrary notes sounded simultaneously.  If their durations are
            -- different that could cause trouble.
            while true do
                -- Do this loop unless we have already whittled away the chord into notes.
                if string.len(rawMatch) <= 1 then
                    break
                end
   
                -- Reprocess the chord into notes and durations.
                startIndex, endIndex, note, noteDuration =
                    string.find(rawMatch,tokenList["TOKEN_NOTE_DURATION"])
            
                if noteDuration == "" or noteDuration == nil then 
                    noteDuration = 1 
                else
                    if string.find(noteDuration, "/") ~= nil then
                
                        if string.sub(noteDuration,1,1) == "/" then
                            noteDuration = "1"..noteDuration 
                        end
                        if noteDuration == "1/" then
                            noteDuration = "1/2"
                        end
                        
                        local numerator = 
                        tonumber(string.sub(noteDuration,1,string.find(noteDuration,"/")-1))
                        local denominator = 
                        tonumber(string.sub(noteDuration,string.find(noteDuration,"/")+1))
                    
                        noteDuration = numerator / denominator
                    end
                end
                
                if note == nil then break end
                
                -- hack for key signature
                --print("note is ".. note)
                firstChar = string.upper(string.sub(note,1,1))
                if firstChar ~= "^" and firstChar ~= "_" then
                    if string.find(self.accidentals,firstChar) ~= nil then 
                        if cycleOfFifthsIndex > 8 then
                            note = "^" .. note
                            --print("added sharp to "..note)
                        end
                        if cycleOfFifthsIndex < 8 then
                            note = "_" .. note
                           -- print("added flat to "..note)
                        end
                    
                    end
                end
                
                if firstChar == "=" then
                    note = string.sub(note,2)
                end
                
                -- This places the notes of the chord into a temporary table which will
                -- be appended to the sound table at the end of the chord.
                table.insert(tempChord,{ABCMusic:convertNoteToPitch(note), ABCMusic:convertDurationToSeconds(noteDuration, self.tempo)})
                -- Whittle away the chord
                rawMatch = string.sub(rawMatch, endIndex + 1) 
            end
            
            
            -- Append chord to sound table.
            table.insert(self.soundTable,tempChord)
            tempChord = {}
        end       
        -- Move to the next token in our strided list of 4.
        parsedTunePointer = parsedTunePointer + 4
    end
end

function ABCMusic:fromTheTop()
   self.soundTablePointer = 1
end 

function ABCMusic:play()
    -- Step through the parsed tune and decide whether to play the next bit yet.
    
  --  if ptempo ~= nil then
      --  self.tempo = ptempo
  --  end
    
    
    -- This normalises the tempo to smooth out lag between cumlative frames.  Meant to be the
    -- same idea for smoothing out animation under variable processing loads.
    self.timeElapsedSinceLastNote = self.timeElapsedSinceLastNote + DeltaTime
    if duration == nil then duration = 0 end
    local framesToBeSkipped = gnDurationSeconds*60
    --( 60 / (self.tempo / 60 )) * (gnDurationSeconds*60) -- tempo = bpm, so / by 60 for bps
    
    -- If there is still a tune and it's time for the next set of notes
    if framesToBeSkipped <= (self.timeElapsedSinceLastNote * 60 ) -- multiply time by 60 to get frames
         and self.soundTablePointer <= #self.soundTable then            -- because draw() is 60 fps
        
        -- Step through the set of notes nested in the sound table, finding each note and
        -- its duration.  If we had volume, we would also want to record it in the most nested
        -- table.
        -- The operator # gives us the number of elements in a table until a blank one - see Lua 
        -- documentation.
        -- Luckily our table will never have holes in it, or the notes would fall through.
        -- The sound table looks like:
        -- 1:    1:    1:    0.456788  -- pitch
        --             2:    0.5            -- seconds duration
        --       2:    1:    0.567890
        --             2:    0.75
        -- 2: etc...
        
        oldTempDuration=0
        tempDuration = 0
        
        for i = 1, #self.soundTable[self.soundTablePointer] do 
            oldTempDuration = tempDuration
            -- This bit plays the note currently being pointed to.  If it is part of a set
            -- to be played at once, this will loop around without delay.
            
           gnPitchBeingPlayed = self.soundTable[self.soundTablePointer][i][1]
            
            
           -- gnNoteBeingPlayed = notes[self.soundTable[self.soundTablePointer][i][1]]
            --print(self.soundTable[self.soundTablePointer][i][2])
            gnDurationSeconds = ( tonumber(self.soundTable[self.soundTablePointer][i][2]))
            --print("temp dur was ".. tempDuration)
        tempDuration = gnDurationSeconds
           -- soundDuration = (tempDuration/2)*(60/self.tempo)
            --print(" sound dur is".. soundDuration)
            if gnPitchBeingPlayed ~= "z" then
                sound({Waveform = 0, StartFrequency = gnPitchBeingPlayed, SustainTime = 0.6*(math.sqrt(gnDurationSeconds))})
            end
            
    
            if self.DEBUG then 
                y = y + 20
                if y > HEIGHT then y=0 end
                background(0, 0, 0, 255)
                text(gnPitchBeingPlayed .." " ..gnDurationSeconds, WIDTH/2, HEIGHT - y)
            end
            
            self.semitoneModifier = 0
            
            -- Keep the shortest note duration of the set of notes to be played together,
            -- to be used as one of the inputs for the delay until the next note.  
           if oldTempDuration ~= 0 and oldTempDuration < tempDuration then
              -- print("overtook " .. tempDuration)
                tempDuration = oldTempDuration
            
            end
        end
      -- print("shortest was " .. tempDuration)
        gnDurationSeconds = tempDuration
    
        
        -- Looping music... we need a better way to do this...
        
        --print(duration)
        if self:hasFinished() then
            if self.LOOP then 
                self.soundTablePointer = 1
            end
        else
            -- Increment the pointer in our sound table.
            self.soundTablePointer = self.soundTablePointer + 1
        end
        
        -- Reset counters rather than going to infinity and beyond.
        self.timeElapsedSinceLastNote = 0
    end
end

function ABCMusic:hasFinished()
    return self.soundTablePointer == #self.soundTable
end

function ABCMusic:noteBeingPlayed()
    return gsNoteBeingPlayed
end

function ABCMusic:convertNoteToPitch(n)
    self.semitoneModifier = 0
                gsNoteBeingPlayed = n
            for j = 1, #gsNoteBeingPlayed do
                local currentChar = string.sub(gsNoteBeingPlayed,j,j)
                
                if currentChar == "_" then 
                    self.semitoneModifier = self.semitoneModifier - 1
                end
                
                if currentChar == "\^" then 
                    self.semitoneModifier = self.semitoneModifier + 1
                    currentChar = "%^"
                end
                -- NB need to implement naturals =
                
                
                -- if the current char is a note
                if string.find("abcdefg",string.lower(currentChar)) ~= nil then
                    
                    -- modify octave
                    -- search through the next characters for , and '
                    local nextCharIndex = 1
                    local nextChar = string.sub(gsNoteBeingPlayed,j+nextCharIndex,j+nextCharIndex)
                    if nextChar == "," then 
                        self.semitoneModifier = self.semitoneModifier - 12
                    end
                    if nextChar == "'" then 
                        self.semitoneModifier = self.semitoneModifier + 12
                    end
                    
                    pos = string.find(gsNoteOrder,currentChar)
                    local tonalModifier = string.sub(gsTonalSystem, 1, pos - 1)
                    
                    for i = 1, #tonalModifier do
        self.semitoneModifier = self.semitoneModifier + tonumber(string.sub(tonalModifier,i,i))
                    end
                    
                end
                            
            end
            
           -- gnNoteBeingPlayed = notes[self.soundTable[self.soundTablePointer][i][1]]
            --print(self.soundTable[self.soundTablePointer][i][2])
            
            pos = self.semitoneModifier + 44
            
            pitch = pitchTable[pos]
            
    return pitch
end

function ABCMusic:convertDurationToSeconds(d,t)
    tempDuration = d
            --print("temp dur was ".. tempDuration)
    soundDuration = (tempDuration/2)*(60/t)
    return soundDuration
end
