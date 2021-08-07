//
//  dump.swift
//  appdump
//
//  Created by paradiseduo on 2021/7/29.
//

import Foundation
import MachO

@_silgen_name("mremap_encrypted")
func mremap_encrypted(_: UnsafeMutableRawPointer, _: Int, _: UInt32, _: UInt32, _: UInt32) -> Int32

class Dump {
    func staticMode(data : UserData, sourceUrl : URL, targetUrl : URL) {
        
        func ulog(str : String = "Unknown error!"){
            DispatchQueue.main.async {
                data.log.append(str)
            }
        }
        
        let fm = FileManager.default

        if !fm.fileExists(atPath: targetUrl.path) {
            do{
                try fm.copyItem(at: sourceUrl, to: targetUrl)
                ulog(str: "Success to copy file.\n")
            }catch{
                ulog(str: "Failed to copy file.\n")
            }
        }
        
        Dump.mapFile(path: sourceUrl.path, mutable: false) { base_size, base_descriptor, base_raw in
            if let base = base_raw {
                Dump.mapFile(path: targetUrl.path, mutable: true) { dupe_size, dupe_descriptor, dupe_raw in
                    if let dupe = dupe_raw {
                        if base_size == dupe_size {
                            let header = UnsafeMutableRawPointer(mutating: dupe).assumingMemoryBound(to: mach_header_64.self)
                            assert(header.pointee.magic == MH_MAGIC_64)
                            assert(header.pointee.cputype == CPU_TYPE_ARM64)
                            assert(header.pointee.cpusubtype == CPU_SUBTYPE_ARM64_ALL)
                            
                            
                            guard var curCmd = UnsafeMutablePointer<load_command>(bitPattern: UInt(bitPattern: header)+UInt(MemoryLayout<mach_header_64>.size)) else {
                                return
                            }
                            
                            var segCmd : UnsafeMutablePointer<load_command>!
                            for _: UInt32 in 0 ..< header.pointee.ncmds {
                                segCmd = curCmd
                                if segCmd.pointee.cmd == LC_ENCRYPTION_INFO_64 {
                                    let command = UnsafeMutableRawPointer(mutating: segCmd).assumingMemoryBound(to: encryption_info_command_64.self)
                                    if Dump.dump(descriptor: base_descriptor, dupe: dupe, info: command.pointee) {
                                        command.pointee.cryptid = 0
                                    }
                                    break
                                }
                                curCmd = UnsafeMutableRawPointer(curCmd).advanced(by: Int(curCmd.pointee.cmdsize)).assumingMemoryBound(to: load_command.self)
                            }
                            munmap(base, base_size)
                            munmap(dupe, dupe_size)
                            ulog(str: "Dump Success\n")
                            DispatchQueue.main.async {
                                NotificationCenter.default.post(name: NSNotification.Name("stop"), object: nil)
                            }
                        } else {
                            munmap(base, base_size)
                            munmap(dupe, dupe_size)
                            ulog(str: "If the files are not of the same size, then they are not duplicates of each other, which is an error.\n")
                        }
                    } else {
                        munmap(base, base_size)
                        ulog(str: "Read Dupe Fail\n")
                    }
                }
            } else {
                ulog(str: "Read Base Fail\n")
            }
        }
    }
    
    static func dump(descriptor: Int32, dupe: UnsafeMutableRawPointer, info: encryption_info_command_64) -> Bool {
        let base = mmap(nil, Int(info.cryptsize), PROT_READ | PROT_EXEC, MAP_PRIVATE, descriptor, off_t(info.cryptoff))
        if base == MAP_FAILED {
            return false
        }
        let error = mremap_encrypted(base!, Int(info.cryptsize), info.cryptid, UInt32(CPU_TYPE_ARM64), UInt32(CPU_SUBTYPE_ARM64_ALL))
        if error != 0 {
            munmap(base, Int(info.cryptsize))
            return false
        }
        memcpy(dupe+UnsafeMutableRawPointer.Stride(info.cryptoff), base, Int(info.cryptsize))
        munmap(base, Int(info.cryptsize))
        
        return true
    }
    
    static func mapFile(path: UnsafePointer<CChar>, mutable: Bool, handle: (Int, Int32, UnsafeMutableRawPointer?)->()) {
        let f = open(path, mutable ? O_RDWR : O_RDONLY)
        if f < 0 {
            handle(0, 0, nil)
            return
        }
        
        var s = stat()
        if fstat(f, &s) < 0 {
            close(f)
            handle(0, 0, nil)
            return
        }
        
        let base = mmap(nil, Int(s.st_size), mutable ? PROT_READ | PROT_WRITE : PROT_READ, mutable ? MAP_SHARED : MAP_PRIVATE, f, 0)
        if base == MAP_FAILED {
            close(f)
            handle(0, 0, nil)
            return
        }
        
        handle(Int(s.st_size), f, base)
    }
    
}
