module.exports = {
  // build: {
  //   "index.html": "index.html",
  //   "app.js": [
  //     "javascripts/app.js"
  //   ],
  //   "app.css": [
  //     "stylesheets/app.css"
  //   ],
  //   "images/": "images/"
  // },
  // deploy: [
  //   "MultiAccess",
  //   "MultiAccessTester",
  //   "MultiAccessTestable",
  //   "MultiAccessPrecise",
  //   "MultiAccessPreciseTester",
  //   "MultiAccessPreciseTestable",
  // ],
  networks: {
    development: {
      host: "localhost",
      port: 8545,
      network_id: "*", // Match any network id
      gas: 5000000
    }
  }
};

// testrpc -l  100000000000000 --account="0x8ef12df3fb135175ba88e9aad222480959bde34915fa81c3727eee1bdf1ee2ee,100000000000000000000000000000"
