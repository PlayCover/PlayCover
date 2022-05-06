//
//  File.swift
//  PlayCover
//
//  Created by Александр Дорофеев on 24.11.2021.
//

import Foundation

typealias BOMCopier = OpaquePointer
typealias BOMSys = OpaquePointer

let BOMHandle = dlopen("/System/Library/PrivateFrameworks/Bom.framework/Bom", RTLD_LAZY)

@_transparent func BOMFunction<T>(_ name: UnsafePointer<CChar>) -> T {
    unsafeBitCast(dlsym(BOMHandle, name), to: T.self)
}

let BomSys_default: @convention(c) () -> BOMSys = BOMFunction("BomSys_default")
let BOMCopierNewWithSys: (
    @convention(c) (BOMSys) -> BOMCopier
) = BOMFunction("BOMCopierNewWithSys")
let BOMCopierFree: (
    @convention(c) (BOMCopier) -> ()
) = BOMFunction("BOMCopierFree")

let kBOMCopierOptionExtractPKZipKey = "extractPKZip"

let BOMCopierCopy: (
    @convention(c) (_ copier: BOMCopier, _ fromObj: UnsafePointer<CChar>, _ toOjb: UnsafePointer<CChar>) -> CInt
) = BOMFunction("BOMCopierCopy")

let BOMCopierCopyWithOptions: (
    @convention(c) (_ copier: BOMCopier, _ fromObj: UnsafePointer<CChar>, _ toObj: UnsafePointer<CChar>, _  options: CFDictionary) -> CInt
) = BOMFunction("BOMCopierCopyWithOptions")

enum BOMCopierReturn: CInt, Error {
    case invalidArgument = 22
    case error = -1
    case success = 0
    case genericError = 1
    case inefficient = 2
    case unsupportedArchive = 3
    case endOfArchive = 4
}

func unzip_to_destination(_ source: UnsafePointer<CChar>, _ destination: UnsafePointer<CChar>) -> BOMCopierReturn {
    let copier = BOMCopierNewWithSys(BomSys_default())
    defer { BOMCopierFree(copier) }
    
    let rawBomCopierReturn = BOMCopierCopyWithOptions(copier, source, destination, [
        "extractPKZip": kCFBooleanTrue
    ] as CFDictionary)
    
    return BOMCopierReturn(rawValue: rawBomCopierReturn)!
}
