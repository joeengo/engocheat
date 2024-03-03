const core = require('@actions/core');
const github = require('@actions/github');
const crypto = require("crypto");
const fs = require("fs");
const path = require("path");

const luaDirectory = path.join(__dirname, "lua");
const manifestLocation = path.join(__dirname, "hash-manifest.json")

let hashedFiles = {};
function hashLuaFiles(Directory) {
    fs.readdirSync(Directory).forEach(File => {
        const filePath = path.join(Directory, File);
        if (fs.statSync(filePath).isDirectory()) {
            return hashLuaFiles(filePath);
        } else {
            const indexPath = `lua${filePath.split("\\lua")[1]}`
            const fileData = fs.readFileSync(filePath);
            const hash = crypto.createHash("sha512").update(fileData).digest("hex");
            hashedFiles[indexPath] = hash
        }
    });
}

hashLuaFiles(luaDirectory)

const jsonData = JSON.stringify(hashedFiles)
fs.writeFileSync(manifestLocation, jsonData)