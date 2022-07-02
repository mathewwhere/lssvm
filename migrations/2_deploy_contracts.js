const LinearCurveArtifact = artifacts.require('./bonding-curves/LinearCurve.sol');
const ExponentialCurveArtifact = artifacts.require('./bonding-curves/ExponentialCurve.sol');
const LSSVMPairEnumerableERC20Artifact = artifacts.require('./LSSVMPairEnumerableERC20.sol');
const LSSVMPairEnumerableETHArtifact = artifacts.require('./LSSVMPairEnumerableETH.sol');
const LSSVMPairMissingEnumerableERC20Artifact = artifacts.require('./LSSVMPairMissingEnumerableERC20.sol');
const LSSVMPairMissingEnumerableETHArtifact = artifacts.require('./LSSVMPairMissingEnumerableETH.sol');
const LSSVMPairFactoryArtifact = artifacts.require('./LSSVMPairFactory.sol');
const LSSVMRouterArtifact = artifacts.require('./LSSVMRouter.sol');

module.exports = async(deployer) => {
  // await deployer.deploy(ExponentialCurveArtifact);
  // await deployer.deploy(LinearCurveArtifact);
  // await deployer.deploy(LSSVMPairEnumerableERC20Artifact);
  // await deployer.deploy(LSSVMPairEnumerableETHArtifact);
  // await deployer.deploy(LSSVMPairMissingEnumerableERC20Artifact);
  // await deployer.deploy(LSSVMPairMissingEnumerableETHArtifact);
  // await deployer.deploy(
  //   LSSVMPairFactoryArtifact,
  //   LSSVMPairEnumerableETHArtifact.address,
  //   LSSVMPairMissingEnumerableETHArtifact.address,
  //   LSSVMPairEnumerableERC20Artifact.address,
  //   LSSVMPairMissingEnumerableERC20Artifact.address,
  //   "0x75d4bdBf6593ed463e9625694272a0FF9a6D346F",
  //   web3.utils.toWei('0.01', 'ether')
  // );
  await deployer.deploy(LSSVMRouterArtifact, "0xb16c1342E617A5B6E4b631EB114483FDB289c0A4");
}