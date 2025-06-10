// FILE: generate-manifest.js
const fs = require('fs');
const path = require('path');
const crypto = require('crypto');

const baseDir = 'engocheat/lua';
const outputFile = 'engocheat/hash-manifest.json';

function sha512(filePath) {
    const data = fs.readFileSync(filePath);
    return crypto.createHash('sha512').update(data).digest('hex');
}

function walk(dir, fileMap = {}) {
    const files = fs.readdirSync(dir);
    for (const file of files) {
        const fullPath = path.join(dir, file);
        const stat = fs.statSync(fullPath);

        if (stat.isFile()) {
            // Keep path format as 'engocheat\\lua\\src\\file.lua'
            const relativePath = path.relative('', fullPath).replace(/\//g, '\\');
            fileMap[relativePath] = sha512(fullPath);
        } else if (stat.isDirectory()) {
            walk(fullPath, fileMap);
        }
    }
    return fileMap;
}

const manifest = walk(baseDir);
fs.writeFileSync(outputFile, JSON.stringify(manifest));
console.log(`[engocheat] hash-manifest.json updated with ${Object.keys(manifest).length} entries.`);
