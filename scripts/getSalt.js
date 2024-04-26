const crypto = require('crypto');

async function generate12ByteSalt(inputString) {
    // Encode the input string into a Uint8Array
    const encoder = new TextEncoder();
    const encodedString = encoder.encode(inputString);

    // Hash the encoded string using SHA-256
    const hashBuffer = await crypto.subtle.digest('SHA-256', encodedString);

    // Convert the hash to a Uint8Array and slice the first 12 bytes
    const hashArray = new Uint8Array(hashBuffer).slice(0, 12);

    // Convert the 12-byte Uint8Array to a hexadecimal string
    const hashHex = Array.from(hashArray).map(b => b.toString(16).padStart(2, '0')).join('');
    console.log(hashHex);
    return hashHex;
}

generate12ByteSalt('27011987');
