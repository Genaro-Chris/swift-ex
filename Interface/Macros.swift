//===----------------------------------------------------------------------===//
//
// This source file is part of the Swift.org open source project
//
// Copyright (c) 2014 - 2023 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See https://swift.org/LICENSE.txt for license information
// See https://swift.org/CONTRIBUTORS.txt for the list of Swift project authors
//
//===----------------------------------------------------------------------===//

import Foundation

@attached(member, names: arbitrary)
@attached(extension, conformances: OptionSet)
public macro MyOptionSet<RawType>() =
    #externalMacro(module: "Implementation", type: "OptionSetMacro")

@attached(peer, names: suffixed(_throws))
public macro throwsToResult(_ name: StaticString) =
    #externalMacro(module: "Implementation", type: "ThrowsToResult")

/// Adds a "completionHandler" variant of an async function, which creates a new
/// task , calls the original async function, and delivers its result to the completion
/// handler.
@attached(peer, names:  arbitrary)// overloaded) // old
public macro AddCompletionHandler(_ completionName: String = "CompletionHandler") =
    #externalMacro(module: "Implementation", type: "AddCompletionHandlerMacro")

@attached(peer, names: overloaded)
public macro AddAsync() =
    #externalMacro(module: "Implementation", type: "AddAsyncMacro")

@attached(member, names: named(CodingKeys))
public macro CustomCodable() = #externalMacro(module: "Implementation", type: "CustomCodable")

@attached(body)
public macro Remote() = #externalMacro(module: "Implementation", type: "RemoteMacro")

@attached(member, names: arbitrary)
public macro DTO() = #externalMacro(module: "Implementation", type: "DTOMacro")

@freestanding(codeItem)
public macro unwrap() = #externalMacro(module: "Implementation", type: "UnwrapMacro")

@attached(preamble)
public macro Traced() = #externalMacro(module: "Implementation", type: "TracedPreambleMacro")

public protocol ConjureRemoteValue {
    static func conjureValue() -> Self
}

extension String: ConjureRemoteValue {
    public static func conjureValue() -> String {
        String(Int.random(in: 0...100000))
    }
}

public func remoteCall<Result: ConjureRemoteValue>(function: String, arguments: [String: Any]) async
    -> Result
{
    let printedArgs = arguments.keys.sorted().map {
        ("\($0): \(arguments[$0]!)")
    }.joined(separator: ", ")
    print("Remote call \(function)(\(printedArgs))")
    return Result.conjureValue()
}

public func logMsg(_ message: String) {
    print(message)
}
