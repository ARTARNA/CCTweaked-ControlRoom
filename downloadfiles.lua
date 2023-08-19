local repositoryURL = "https://github.com/ARTARNA/CCTweaked-ControlRoom/"
local destinationDir = "/"

local function downloadFile(url, filePath)
    local response = http.get(url)
    if response then
        local content = response.readAll()
        response.close()

        local file = fs.open(filePath, "w")
        file.write(content)
        file.close()

        return true
    else
        return false
    end
end

-- List of files to download
local filesToDownload = {
    "DisplayPC.lua",
    "MatrixDetection.lua",
    "output.lua"
}

-- Create the destination directory if it doesn't exist
if not fs.exists(destinationDir) then
    fs.makeDir(destinationDir)
end

-- Download each file
for _, fileName in ipairs(filesToDownload) do
    local fileURL = repositoryURL .. "raw/main/" .. fileName
    local filePath = fs.combine(destinationDir, fileName)

    print("Downloading " .. fileName .. "...")
    if downloadFile(fileURL, filePath) then
        print("Downloaded " .. fileName)
    else
        print("Failed to download " .. fileName)
    end
end

print("Download complete!")
