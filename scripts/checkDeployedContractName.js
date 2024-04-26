const { ethers } = require("ethers");

async function main() {
    const contractAddress = '0xcf3d4469547BF520C72940230EbCe09a2AF2F4c6';
    const provider = new ethers.providers.JsonRpcProvider('https://sepolia.base.org');
    const contract = new ethers.Contract(contractAddress, ['function _name() view returns (string)'], provider);
    const name = await contract._name();
    console.log(name);
}
main();