-- 1. Function to get POSIX path safely (Defined outside the 'on run' block)
-- This makes the handler globally accessible.
on get_posix_path(rawPath)
	-- We use 'as alias' to force the system to confirm the file exists using the HFS path format
	-- and then convert to the POSIX format the 'set picture to' command needs.
	try
		return POSIX path of (rawPath as alias)
	on error
		return missing value -- Return missing value if file not found
	end try
end get_posix_path

-- 2. Main execution block
on run {input, parameters}
	-- Use the system path to the user's home folder for robust HFS path resolution.
	set homeFolder to (path to home folder as text)
	
	-- Concatenate the rest of the HFS path (note: we use a colon after "Pictures")
	set picturesFolder to homeFolder & "Pictures:Wallpaper:Automated:"
	
	tell application "System Events"
		set desktopCount to count of desktops
		log "Applying wallpaper for Focus Mode: " & input & " on " & desktopCount & " desktops."
		
		-- 3. Conditional Logic to Determine Wallpaper Path Construction
    -- Some wallpaper files are dynamic (like the Travel one, which changes based on location) and
    -- are in HEIC format. This requires different treatment to standard JPEG.
		if input contains "Travel" then
			-- Case 1: Dynamic HEIC (Single file for ALL desktops)
			set pictureFormat to ".heic"
			set pictureBaseName to input & pictureFormat -- e.g., "Travel.heic"
			set rawHFSPath to picturesFolder & pictureBaseName
			
			log "Attempting to load dynamic HEIC: " & pictureBaseName
			
			-- Call the globally defined function
			set targetPath to my get_posix_path(rawHFSPath)
			
			if targetPath is missing value then
				log "!!! ERROR: The dynamic HEIC file '" & pictureBaseName & "' does not exist. Halting script."
				return
			end if
			
			-- Set the SAME file on every desktop
			repeat with desktopNumber from 1 to desktopCount
				tell desktop desktopNumber
					set picture to targetPath
				end tell
			end repeat
			
		else
			-- Case 2: Static JPEG (Unique file per desktop/monitor)
			log "Using monitor-specific JPEGs."
			set pictureFormat to ".jpeg"
			
			-- Loop and set a UNIQUE file for each desktop
			repeat with desktopNumber from 1 to desktopCount
				-- Example file name: "Personal-1.jpeg"
				set pictureBaseName to input & "-" & desktopNumber & pictureFormat
				set rawHFSPath to picturesFolder & pictureBaseName
				
				log "Attempting to load JPEG for Desktop " & desktopNumber & ": " & pictureBaseName
				
				-- Call the globally defined function
				set targetPath to my get_posix_path(rawHFSPath)
				
				if targetPath is missing value then
					log "!!! WARNING: JPEG file '" & pictureBaseName & "' not found. Skipping desktop " & desktopNumber & "."
				else
					tell desktop desktopNumber
						set picture to targetPath
					end tell
					log "Desktop " & desktopNumber & " set successfully."
				end if
			end repeat
			
		end if
		
	end tell
	
	-- 4. Force a system refresh (Crucial for stability)
	delay 0.5
	try
		do shell script "killall Dock"
	on error
		-- Ignore error
	end try
	
	-- 5. Toggle Desktop Widgets based on Focus Mode
	if (input as text) is "Keynote" or (input as text) is "Prayer" then
		-- Hide desktop widgets and refresh the Window Manager
		do shell script "defaults write com.apple.WindowManager StandardHideWidgets -int 1; killall WindowManager"
	else
		-- Show desktop widgets and refresh the Window Manager
		do shell script "defaults write com.apple.WindowManager StandardHideWidgets -int 0; killall WindowManager"
	end if
	
	
	return input
end run
