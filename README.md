# EncryptCardTests
[![build and test][badge.svg]][build-and-test.yml]

## Acceptance Tests for EncryptCard Swift Package

To verify that [EncryptCard][] encryption is the same as [PGEncrypt][] we run encrypt same sample data and decrypt it using same sample private key.

Compare  [testDecryptPGEncrypt][testDecryptPGEncrypt] and [testDecryptEncrypt][testDecryptEncrypt]

This repository is separate from Swift Package https://github.com/Lucra-Sports/EncryptCard
 - to allow Swift Package Manager download package faster without large dependencies and extra files used by acceptance tests.
 - SPM requires package to Package.swift at the top level of the repo. See https://forums.swift.org/t/spm-multi-package-repositories/43193

[badge.svg]: https://github.com/Lucra-Sports/EncryptCardTests/actions/workflows/build-and-test.yml/badge.svg
[build-and-test.yml]: https://github.com/Lucra-Sports/EncryptCardTests/actions/workflows/build-and-test.yml
[PGEncrypt]: https://github.com/strues/react-native-nmi-bridge/blob/af6afde829f93c75959a221cb94331bc0875f83b/ios/Payment%20Gateway%20SDK/PGMobileSDK/PGEncrypt.h#L18-L23
[EncryptCard]: https://github.com/Lucra-Sports/EncryptCard/blob/13b12b48ad3baafda3aa9436e40b4f5da3e1f0ea/Sources/EncryptCard.swift#L58-L60
[testDecryptPGEncrypt]: https://github.com/Lucra-Sports/EncryptCardTests/blob/d097922fee3e4b0280676664c33f658a90c603c5/AcceptanceTests/AcceptanceTest.swift#L14-L23
[testDecryptEncrypt]: https://github.com/Lucra-Sports/EncryptCardTests/blob/d097922fee3e4b0280676664c33f658a90c603c5/AcceptanceTests/AcceptanceTest.swift#L24-L29
