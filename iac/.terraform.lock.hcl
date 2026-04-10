# This file is maintained automatically by "terraform init".
# Manual edits may be lost in future updates.

provider "registry.terraform.io/azure/azapi" {
  version     = "2.9.0"
  constraints = ">= 1.14.0, ~> 2.0, < 3.0.0"
  hashes = [
    "h1:lN0C7TI2dqStnZysEBhDq33t9DbpUp/8rOWxZUF/st0=",
    "zh:0a4eee8c9362db6ca19d371eccf38701c8306be761182da87b624294f7e8f867",
    "zh:4df87bee5b8f4cce27461ae26132a599542583cdf035942b42b0259a514ab46e",
    "zh:57dc1f4227f1d0eab630fcf868d6c9a1b4dc4c165608ce5a4d7028a482770547",
    "zh:5c500e42c419c324ea8f41c40e4cc8af187323cebc9f70543749b6c0e59c0fe9",
    "zh:6c7dca31242e27d2f215b1a9370b65579b3a988282a3609564ea96866f86f0ca",
    "zh:74dada7351b25d01e61aa70aa8cf1f1fb96d09c514be4b66d12816c5e61f9e01",
    "zh:9c67c0727ab8be15879793f929f3d71f0f149ae1daaf577d0bd4d57b2e61c408",
    "zh:a0266da16db14b635a61d6766efc28468056bac91ed6662fc9f2a0aad923b063",
    "zh:a4a555627f40fa797b34ddede599812cddb1e0e9be105ccfcf1f293451b97cd7",
    "zh:a6a1c4a46f4f01e4420a456adefe8bcf3bff3c9d09a8dfeedeea5b94c866dfd8",
    "zh:c64fc4067a8276d4405d9359990e0c45e66dba07433a1f3ab1e6c32f6ef3b048",
    "zh:ee77a881d071b3a0ad8a64f9c1158e3aee9b37e9063de5dd8fa9d238dbe70ba1",
  ]
}

provider "registry.terraform.io/azure/modtm" {
  version     = "0.3.5"
  constraints = "~> 0.3"
  hashes = [
    "h1:cz/8D3irnZwmEzBbCHM2l/wZUOe0qwt6ocQL09513n8=",
    "zh:02a54109f2bd30a089a0681eaba8ef9d30b0402a51795597ee7b067f04952417",
    "zh:0a15492a7257a0979d1f1d501168d1a38ec8c65b11d89d9423349f143d7b7e67",
    "zh:4ae1d114aec1625f192eb2055eb7301774a8f79340085fbbe7c2d11284ba4cb7",
    "zh:599201c19e82a227f0739be2150779e42903ba0aa147e96ef219c7f32f926053",
    "zh:747b1189e679cd7cf77f76fd09609db0ac1ef7189ec3c64accd37af7d0ebe449",
    "zh:859bc8739ceb9049e7cd98284f22eb9d503cc5b80f9452ee28a518080ebf3903",
    "zh:8f97c0876b30967b47dfd63546f3843368bc3bc90e98bb42bd33c00ffe2d0b2c",
    "zh:91183bbea386e6013d0b2a3b1d36a7bfe1595d45f4ee1f4f693d6254d017d334",
    "zh:ae16303a74c83e0d8f4413d568eaf04c3c0d2b07250dbd7ae07bffae01197f36",
    "zh:db155386bb65a7fd5569b7d3331de65a259638e8e1c8f8896db969f4599504a9",
    "zh:e39e6089c8a17a4b26b59c95050bd0e19fc0a09a14314cfa139053269b6d5f8d",
    "zh:ec880b514fc3bd8d07e5d66a0c528fd6d83ae62d6588df4939b1f6ea509f0b24",
  ]
}

provider "registry.terraform.io/hashicorp/azuread" {
  version     = "3.4.0"
  constraints = ">= 2.53.0, ~> 3.3, < 3.5.0"
  hashes = [
    "h1:rfO7hSYJLdpff/s2iuooHtxNacwKq5n03IwvVQ+xbSI=",
    "zh:035a6d6e6aa7f117969702873c27344ec4ddd88f676cebc1088316fb26d5c95a",
    "zh:11f86935174d8223699cae00b3a705ded1d75a4efb6d4723d3788f5446e1eaa5",
    "zh:16d52b5bf8eefa98cd2793122be0c5a7b41767caedbd8a08786aeefb3d0c6856",
    "zh:1c3e89cf19118fc07d7b04257251fc9897e722c16e0a0df7b07fcd261f8c12e7",
    "zh:2fe201c7a1c17279f7674c160861296015d9b9d120de598999d169398ce285c9",
    "zh:37bb91dff5b751f0c86a02a12980bdb5935d2ca6cdd249d9eef7eca619f628c0",
    "zh:7533a35300e411893a024f858e722e50107dfd7212236d396ebf2ca2b13b7bcc",
    "zh:88a95b2cb606439ae2f60ebe63a800580e232e94bc1b02ac7d25d25be10cb511",
    "zh:c7b138b6bc34d8a1eff91742b38bce1718d9c50c343393fdfc918bef022ed74f",
    "zh:cab09fda45b8a9a9896aedb22f5829745b7e9a01abb8077696bccb170fb01b5f",
    "zh:cc4a29f074f1cc25f3abd3a41444f68307f3eb08c4d5f79f60a012b632c1ea05",
    "zh:e30e9fe8e04271431cb730a1a888b6da5afeae385e2e53ff7b4114066c1250db",
  ]
}

provider "registry.terraform.io/hashicorp/azurerm" {
  version     = "4.68.0"
  constraints = ">= 3.71.0, >= 3.116.0, >= 3.117.0, >= 4.0.0, ~> 4.0, >= 4.8.0, >= 4.17.0, >= 4.19.0, >= 4.21.1, < 5.0.0"
  hashes = [
    "h1:oLcXwy3gUI3E+LxA6user9HvWljqI0AyDLAIrTJvjoE=",
    "zh:08865385ea0c84d208d6ca16644336466e836d56c3639ac369210dbcb9187fb1",
    "zh:0a42695cb13eefe955ad183e560a8bd35cfb714834525fd5b3749d66d347a562",
    "zh:195b77405fc54bfc21aa0b20f63f34ad0362fe856cdade7db5a11cd16ae53d4d",
    "zh:78d5eefdd9e494defcb3c68d282b8f96630502cac21d1ea161f53cfe9bb483b3",
    "zh:996d0baa2d8462c55631f7c7982b8786ef7f632e3b401ebb596339178b7941a0",
    "zh:99d43f9edfe225ade0069bd53634c7ae9208297c65db50f26ba5a31c1df3c9c3",
    "zh:9e7a9d4dee8fd53dba6b0adf5485400f07ee0c603a079000e6246ca69e7ecfd4",
    "zh:a59ce7d80bc451f03c88afd97cd5effad3079cea4974f0350527abec805e1fd4",
    "zh:a9a6772178c1e40203c48a56ae611fb09625d1db64357c04ead34b60249188a3",
    "zh:bdf0f56843cb67174cb32a2956701ac1b68bbdc5c311c62900de72f247d3d42d",
    "zh:d02a5cd102ef3bfd98373b4d5e711b2f2d403595f4606fc29a897167da36edba",
    "zh:dbbbb5a9da53e4a71b0b996c3abb9fe3f7422e07f50f5cf2f6eb56fa4ddd66e1",
  ]
}

provider "registry.terraform.io/hashicorp/random" {
  version     = "3.6.2"
  constraints = ">= 3.0.0, >= 3.3.2, >= 3.5.0, ~> 3.5, ~> 3.6, 3.6.2, < 4.0.0"
  hashes = [
    "h1:5lstwe/L8AZS/CP0lil2nPvmbbjAu8kCaU/ogSGNbxk=",
    "zh:0ef01a4f81147b32c1bea3429974d4d104bbc4be2ba3cfa667031a8183ef88ec",
    "zh:1bcd2d8161e89e39886119965ef0f37fcce2da9c1aca34263dd3002ba05fcb53",
    "zh:37c75d15e9514556a5f4ed02e1548aaa95c0ecd6ff9af1119ac905144c70c114",
    "zh:4210550a767226976bc7e57d988b9ce48f4411fa8a60cd74a6b246baf7589dad",
    "zh:562007382520cd4baa7320f35e1370ffe84e46ed4e2071fdc7e4b1a9b1f8ae9b",
    "zh:5efb9da90f665e43f22c2e13e0ce48e86cae2d960aaf1abf721b497f32025916",
    "zh:6f71257a6b1218d02a573fc9bff0657410404fb2ef23bc66ae8cd968f98d5ff6",
    "zh:78d5eefdd9e494defcb3c68d282b8f96630502cac21d1ea161f53cfe9bb483b3",
    "zh:9647e18f221380a85f2f0ab387c68fdafd58af6193a932417299cdcae4710150",
    "zh:bb6297ce412c3c2fa9fec726114e5e0508dd2638cad6a0cb433194930c97a544",
    "zh:f83e925ed73ff8a5ef6e3608ad9225baa5376446349572c2449c0c0b3cf184b7",
    "zh:fbef0781cb64de76b1df1ca11078aecba7800d82fd4a956302734999cfd9a4af",
  ]
}

provider "registry.terraform.io/hashicorp/time" {
  version     = "0.13.1"
  constraints = "~> 0.9, ~> 0.12"
  hashes = [
    "h1:5l8PAnxPdoUPqNPuv1dAr3efcCCtSCnY+Vj2nSGkQmw=",
    "zh:02cb9aab1002f0f2a94a4f85acec8893297dc75915f7404c165983f720a54b74",
    "zh:04429b2b31a492d19e5ecf999b116d396dac0b24bba0d0fb19ecaefe193fdb8f",
    "zh:26f8e51bb7c275c404ba6028c1b530312066009194db721a8427a7bc5cdbc83a",
    "zh:772ff8dbdbef968651ab3ae76d04afd355c32f8a868d03244db3f8496e462690",
    "zh:78d5eefdd9e494defcb3c68d282b8f96630502cac21d1ea161f53cfe9bb483b3",
    "zh:898db5d2b6bd6ca5457dccb52eedbc7c5b1a71e4a4658381bcbb38cedbbda328",
    "zh:8de913bf09a3fa7bedc29fec18c47c571d0c7a3d0644322c46f3aa648cf30cd8",
    "zh:9402102c86a87bdfe7e501ffbb9c685c32bbcefcfcf897fd7d53df414c36877b",
    "zh:b18b9bb1726bb8cfbefc0a29cf3657c82578001f514bcf4c079839b6776c47f0",
    "zh:b9d31fdc4faecb909d7c5ce41d2479dd0536862a963df434be4b16e8e4edc94d",
    "zh:c951e9f39cca3446c060bd63933ebb89cedde9523904813973fbc3d11863ba75",
    "zh:e5b773c0d07e962291be0e9b413c7a22c044b8c7b58c76e8aa91d1659990dfb5",
  ]
}
