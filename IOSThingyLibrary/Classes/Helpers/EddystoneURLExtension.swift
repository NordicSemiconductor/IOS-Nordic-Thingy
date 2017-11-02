/*
 Copyright (c) 2010 - 2017, Nordic Semiconductor ASA
 All rights reserved.
 
 Redistribution and use in source and binary forms, with or without modification,
 are permitted provided that the following conditions are met:
 
 1. Redistributions of source code must retain the above copyright notice, this
 list of conditions and the following disclaimer.
 
 2. Redistributions in binary form, except as embedded into a Nordic
 Semiconductor ASA integrated circuit in a product or a software update for
 such product, must reproduce the above copyright notice, this list of
 conditions and the following disclaimer in the documentation and/or other
 materials provided with the distribution.
 
 3. Neither the name of Nordic Semiconductor ASA nor the names of its
 contributors may be used to endorse or promote products derived from this
 software without specific prior written permission.
 
 4. This software, with or without modification, must only be used with a
 Nordic Semiconductor ASA integrated circuit.
 
 5. Any software provided in binary form under this license must not be reverse
 engineered, decompiled, modified and/or disassembled.
 
 THIS SOFTWARE IS PROVIDED BY NORDIC SEMICONDUCTOR ASA "AS IS" AND ANY EXPRESS
 OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES
 OF MERCHANTABILITY, NONINFRINGEMENT, AND FITNESS FOR A PARTICULAR PURPOSE ARE
 DISCLAIMED. IN NO EVENT SHALL NORDIC SEMICONDUCTOR ASA OR CONTRIBUTORS BE
 LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
 CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE
 GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
 HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT
 LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT
 OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */
//
//  URLExtension.swift
//
//  Created by Mostafa Berg on 11/10/16.
//
//

extension URL {
    public static let eddystoneUrlSchemes = ["http://www.", "https://www.", "http://", "https://"]
    internal static let eddystoneExtensions = [".com/", ".org/", ".edu/", ".net/", ".info/", ".biz/", ".gov/", ".com", ".org", ".edu", ".net", ".info", ".biz", ".gov"]

    public var eddystoneUrlSchemeCode: UInt8? {
        var code : UInt8 = 0
        for aScheme in URL.eddystoneUrlSchemes {
            if absoluteString.contains(aScheme) {
                return code
            }
            code += 1
        }
        return nil
    }
    
    public var eddystoneUrlSufix: String? {
        let urlSchemeCode = eddystoneUrlSchemeCode
        
        guard urlSchemeCode != nil else {
            print("Error: URL format is not supported")
            return nil
        }
        
        let schemeIndex = absoluteString.range(of: URL.eddystoneUrlSchemes[Int(urlSchemeCode!)])
        return String(absoluteString[schemeIndex!.upperBound...])
    }

    private func eddystoneDomainExtensionCode() -> UInt8? {
        var code : UInt8 = 0
        for anExtension in URL.eddystoneExtensions {
            if absoluteString.contains(anExtension) {
                return code
            }
            code += 1
        }
        return nil
    }

    public init?(withEddystoneData data: Data) {
        // A URL must have at least 3 bytes: scheme, one byte, extension (domain)
        if data.count < 3 || data[0] > 3 || data[0] < 0 {
            return nil
        }
        
        var urlString = String()
        var offset = 0
        for aByte in [UInt8](data) {
            if offset == 0 {
                if aByte <= 3 && aByte >= 0 {
                    urlString.append(URL.eddystoneUrlSchemes[Int(aByte)])
                } else {
                    urlString.append(Character(UnicodeScalar(aByte)))
                }
            } else {
                if aByte <= 13 && aByte >= 0 {
                    urlString.append(URL.eddystoneExtensions[Int(aByte)])
                } else {
                    urlString.append(Character(UnicodeScalar(aByte)))
                }
            }
            
            offset += 1
        }
        self.init(string: urlString)!
    }

    public func eddystoneEncodedData() -> Data? {
        let urlSchemeCode = eddystoneUrlSchemeCode

        guard urlSchemeCode != nil else {
            print("Error: URL format is not supported")
            return nil
        }

        //Everything is safe, url can now be encoded!
        let originalUrl = absoluteString
        var encodedUrl = Data()
        let extensionCode = eddystoneDomainExtensionCode()
        let schemeIndex = originalUrl.range(of: URL.eddystoneUrlSchemes[Int(urlSchemeCode!)])

        encodedUrl.append(urlSchemeCode!)

        if extensionCode != nil {
            //Get rest of string up til extension code
            let extensionIndex = originalUrl.range(of: URL.eddystoneExtensions[Int(extensionCode!)])
            let domainName = originalUrl[schemeIndex!.upperBound..<extensionIndex!.lowerBound]
            let domainNameArray = domainName.utf8.map({ UInt8($0)})
            encodedUrl.append(domainNameArray, count: domainNameArray.count)
            
            //Append extension code
            encodedUrl.append(extensionCode!)
           
            //Get everything after extension
            var resourceName = originalUrl[extensionIndex!.upperBound...]
            let resourceNameArary = resourceName.utf8.map({ UInt8($0)})
            
            //And append resource
            encodedUrl.append(resourceNameArary, count: resourceNameArary.count)
        } else {
            //Get rest of string up til last slash
            let customDomain = originalUrl[schemeIndex!.upperBound...]
            let customDomainArray = customDomain.utf8.map({ UInt8($0)})
            encodedUrl.append(customDomainArray, count: customDomainArray.count)
        }
        
        guard encodedUrl.count <= 18 else {
            print("Error: Generated Eddystone URL was \(encodedUrl.count), maximum supported length is 18 bytes")
            return nil
        }
        return encodedUrl
    }
}
