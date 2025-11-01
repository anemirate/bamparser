# Badbunny BAM Parser
PoC BAM registry parser that does signature filtering to only display unvalidated/deleted file executions.
Mainly used for detecting cheats and/or executed malware. This can get bypassed by deleted Registry Keys but is a key note in manual screenshares.
I will update this at some point when I stop procrasinating but as for right now this should work fine.

# How to run the script
. You can either run it via a raw content github link like the one pasted here: powershell -ExecutionPolicy Bypass -Command "& { iex (iwr 'https://raw.githubusercontent.com/anemirate/bamparser/main/badbunny.ps1' -UseBasicParsing) }"
. If you don't want to you can download the file and run it this way: powershell -ExecutionPolicy Bypass -File "The file path here"
<img width="1633" height="1249" alt="image" src="https://github.com/user-attachments/assets/06b6903d-49be-4dd5-bab4-8c6c6cbfc5eb" />
<img width="1784" height="866" alt="image" src="https://github.com/user-attachments/assets/c41a8dbe-b907-4be5-8901-98b11272e568" />
