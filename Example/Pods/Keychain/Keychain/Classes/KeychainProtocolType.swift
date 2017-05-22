//
//  KeychainProtocolType.swift
//  Pods
//
//  Created by Ardalan Samimi on 24/05/16.
//
//
import Foundation

public enum KeychainProtocolType: Int {

  case ftp
  case ftps
  case ftpProxy
  case ftpAccount
  case http
  case https
  case httpProxy
  case httpsProxy
  case irc
  case ircs
  case nntp
  case nntps
  case pop3
  case pop3S
  case smtp
  case socks
  case imap
  case imaps
  case ldap
  case ldaps
  case appleTalk
  case afp
  case telnet
  case telnetS
  case ssh
  case smb
  case rtsp
  case rtspProxy
  case daap
  case daaps
  case eppc
  case ipp
  
  public init(rawValue: String) {
    switch rawValue {
    case kSecAttrProtocolFTP as String as String:
      self = .ftp
    case kSecAttrProtocolFTPS as String as String:
      self = .ftps
    case kSecAttrProtocolFTPProxy as String as String:
      self = .ftpProxy
    case kSecAttrProtocolFTPAccount as String as String:
      self = .ftpAccount
    case kSecAttrProtocolHTTP as String as String:
      self = .http
    case kSecAttrProtocolHTTPS as String as String:
      self = .https
    case kSecAttrProtocolHTTPProxy as String as String:
      self = .httpProxy
    case kSecAttrProtocolIRC as String as String:
      self = .irc
    case kSecAttrProtocolIRCS as String as String:
      self = .ircs
    case kSecAttrProtocolNNTP as String as String:
      self = .nntp
    case kSecAttrProtocolNNTPS as String as String:
      self = .nntps
    case kSecAttrProtocolPOP3 as String as String:
      self = .pop3
    case kSecAttrProtocolPOP3S as String as String:
      self = .pop3S
    case kSecAttrProtocolSMTP as String as String:
      self = .smtp
    case kSecAttrProtocolSOCKS as String as String:
      self = .socks
    case kSecAttrProtocolIMAP as String as String:
      self = .imap
    case kSecAttrProtocolIMAPS as String as String:
      self = .imaps
    case kSecAttrProtocolLDAP as String as String:
      self = .ldap
    case kSecAttrProtocolLDAPS as String as String:
      self = .ldaps
    case kSecAttrProtocolAppleTalk as String as String:
      self = .appleTalk
    case kSecAttrProtocolAFP as String as String:
      self = .afp
    case kSecAttrProtocolTelnet as String as String:
      self = .telnet
    case kSecAttrProtocolTelnetS as String as String:
      self = .telnetS
    case kSecAttrProtocolSSH as String as String:
      self = .ssh
    case kSecAttrProtocolSMB as String as String:
      self = .smb
    case kSecAttrProtocolRTSP as String as String:
      self = .rtsp
    case kSecAttrProtocolRTSPProxy as String as String:
      self = .rtspProxy
    case kSecAttrProtocolDAAP as String as String:
      self = .daap
    case kSecAttrProtocolLDAPS as String as String:
      self = .daaps
    case kSecAttrProtocolEPPC as String as String:
      self = .eppc
    case kSecAttrProtocolIPP as String as String:
      self = .ipp
    default:
      self = .http
    }
  }
  
  public var rawValue: String {
    switch self {
    case .ftp:
      return kSecAttrProtocolFTP as String
    case .ftps:
      return kSecAttrProtocolFTPS as String
    case .ftpProxy:
      return kSecAttrProtocolFTPProxy as String
    case .ftpAccount:
      return kSecAttrProtocolFTPAccount as String
    case .http:
      return kSecAttrProtocolHTTP as String
    case .https:
      return kSecAttrProtocolHTTPS as String
    case .httpProxy:
      return kSecAttrProtocolHTTPProxy as String
    case .httpsProxy:
      return kSecAttrProtocolHTTPSProxy as String
    case .irc:
      return kSecAttrProtocolIRC as String
    case .ircs:
      return kSecAttrProtocolIRCS as String
    case .nntp:
      return kSecAttrProtocolNNTP as String
    case .nntps:
      return kSecAttrProtocolNNTPS as String
    case .pop3:
      return kSecAttrProtocolPOP3 as String
    case .pop3S:
      return kSecAttrProtocolPOP3S as String
    case .smtp:
      return kSecAttrProtocolSMTP as String
    case .socks:
      return kSecAttrProtocolSOCKS as String
    case .imap:
      return kSecAttrProtocolIMAP as String
    case .imaps:
      return kSecAttrProtocolIMAPS as String
    case .ldap:
      return kSecAttrProtocolLDAP as String
    case .ldaps:
      return kSecAttrProtocolLDAPS as String
    case .appleTalk:
      return kSecAttrProtocolAppleTalk as String
    case .afp:
      return kSecAttrProtocolAFP as String
    case .telnet:
      return kSecAttrProtocolTelnet as String
    case .telnetS:
      return kSecAttrProtocolTelnetS as String
    case .ssh:
      return kSecAttrProtocolSSH as String
    case .smb:
      return kSecAttrProtocolSMB as String
    case .rtsp:
      return kSecAttrProtocolRTSP as String
    case .rtspProxy:
      return kSecAttrProtocolRTSPProxy as String
    case .daap:
      return kSecAttrProtocolDAAP as String
    case .daaps:
      return kSecAttrProtocolLDAPS as String
    case .eppc:
      return kSecAttrProtocolEPPC as String
    case .ipp:
      return kSecAttrProtocolIPP as String
    }
  }
  
}
