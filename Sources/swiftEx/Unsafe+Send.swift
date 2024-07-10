@propertyWrapper
@dynamicMemberLookup
public struct UncheckedSendable<Value: ~Copyable>: ~Copyable, @unchecked Sendable {

    private var value: Value

    public init(_ value: consuming Value) {
        self.value = value
    }

    public init(wrappedValue: consuming Value) {
        self.value = wrappedValue
    }

    public subscript<T>(dynamicMember memberKeyPath: KeyPath<Value, T>) -> T {
        value[keyPath: memberKeyPath]
    }

    public var wrappedValue: Value {
        _read { yield value }
        _modify { yield &value }
    }

    public subscript<T>(dynamicMember memberKeyPath: WritableKeyPath<Value, T>) -> T {
        _read { yield value[keyPath: memberKeyPath] }
        _modify { yield &value[keyPath: memberKeyPath] }
    }

    public consuming func getValue() -> Value {
        return value
    }

}

extension UncheckedSendable {
    public var projectedValue: Self { Self(self.getValue()) }
}

extension UncheckedSendable: Copyable where Value: Copyable {}

extension UncheckedSendable: Equatable where Value: Equatable {}
extension UncheckedSendable: Hashable where Value: Hashable {}

extension UncheckedSendable: Decodable where Value: Decodable {
    public init(from decoder: any Decoder) throws {
        do {
            let container: any SingleValueDecodingContainer = try decoder.singleValueContainer()
            self.init(try container.decode(Value.self))
        } catch {
            self.init(try Value(from: decoder))
        }
    }
}

extension UncheckedSendable: Encodable where Value: Encodable {
    public func encode(to encoder: any Encoder) throws {
        do {
            var container: any SingleValueEncodingContainer = encoder.singleValueContainer()
            try container.encode(self.value)
        } catch {
            try self.value.encode(to: encoder)
        }
    }
}

public struct UnsafeThrowingClosure<Input, Output>: @unchecked Sendable {
    let body: (Input) throws -> UncheckedSendable<Output>
    public init(body block: @escaping (Input) throws -> Output) {
        body = { (input: Input) -> UncheckedSendable<Output> in
            return UncheckedSendable(try block(input))
        }
    }
    public func callAsFunction(_ value: Input) throws -> Output {
        return try body(value).getValue()
    }

    public func unsafeReturn(input: Input) throws -> UncheckedSendable<Output> {
        return try body(input)
    }
}

public struct UnsafeClosure<Input, Output>: @unchecked Sendable {
    let body: (Input) -> UncheckedSendable<Output>
    public init(body block: @escaping (Input) -> Output) {
        body = { (input: Input) -> UncheckedSendable<Output> in
            return UncheckedSendable(block(input))
        }
    }
    public func callAsFunction(_ value: Input) -> Output {
        return body(value).getValue()
    }

    public func unsafeReturn(input: Input) -> UncheckedSendable<Output> {
        return body(input)
    }
}

public struct AsyncUnsafeClosure<Input, Output>: @unchecked Sendable {
    let body: (Input) async -> UncheckedSendable<Output>
    public init(body block: @escaping (Input) async -> Output) {
        body = { (input: Input) -> UncheckedSendable<Output> in
            await UncheckedSendable(block(input))
        }
    }
    public func callAsFunction(_ value: Input) async -> Output {
        return await body(value).getValue()
    }

    public func unsafeReturn(input: Input) async -> UncheckedSendable<Output> {
        return await body(input)
    }
}

public struct AsyncUnsafeThrowingClosure<Input, Output>: @unchecked Sendable {
    let body: (Input) async throws -> UncheckedSendable<Output>
    public init(body block: @escaping (Input) async throws -> Output) {
        body = { (input: Input) -> UncheckedSendable<Output> in
            return await UncheckedSendable(try block(input))
        }
    }
    public func callAsFunction(_ value: Input) async throws -> Output {
        return try await body(value).getValue()
    }

    public func unsafeReturn(input: Input) async throws -> UncheckedSendable<Output> {
        return try await body(input)
    }
}

/* #if hasAttribute(IsolatedAny) || hasFeature(IsolatedAny) || $IsolatedAny
    @_allowFeatureSuppression(IsolatedAny)
    public struct UnsafeThrowingIsolatedClosure<Input, Output: Copyable>: @unchecked Sendable {
        let body:
            (isolated (any Actor)?, UncheckedSendable<Input>) throws -> UncheckedSendable<
                Output
            >
        let isolation: (any Actor)?
        public init(@_inheritActorContext body: @escaping @isolated(any) (Input) throws -> Output) {
            isolation = body.isolation
            let newBlock: (Input) throws -> Output = body
            self.body = { (a: isolated (Actor)?, input: UncheckedSendable<Input>) throws in
                return UncheckedSendable(try newBlock(input.getValue()))
            }
        }
        public func callAsFunction(_ value: Input) async throws -> Output {
            return try await self.body(self.isolation, UncheckedSendable(value)).getValue()
        }

        public func unsafeReturn(input: Input) async throws -> UncheckedSendable<Output> {
            return try await body(isolation, UncheckedSendable(input))
        }
    }

    @_allowFeatureSuppression(IsolatedAny)
    public struct UnsafeIsolatedClosure<Input, Output: Copyable>: @unchecked Sendable {
        let body: (isolated (any Actor)?, UncheckedSendable<Input>) -> UncheckedSendable<Output>
        let isolation: (any Actor)?
        public init(@_inheritActorContext body: @escaping @isolated(any) (Input) -> Output) {
            isolation = body.isolation
            let newBlock: (Input) -> Output = body
            self.body = { (a: isolated (Actor)?, input: UncheckedSendable<Input>) in
                return UncheckedSendable(newBlock(input.getValue()))
            }
        }
        public func callAsFunction(_ value: Input) async -> Output {
            return await self.body(self.isolation, UncheckedSendable(value)).getValue()
        }

        public func unsafeReturn(input: Input) async -> UncheckedSendable<Output> {
            return await body(isolation, UncheckedSendable(input))
        }
    }

    @_allowFeatureSuppression(IsolatedAny)
    public struct AsyncUnsafeIsolatedClosure<Input, Output>: @unchecked Sendable {
        let body:
            (isolated (any Actor)?, UncheckedSendable<Input>) async -> UncheckedSendable<
                Output
            >
        let isolation: (any Actor)?
        public init(@_inheritActorContext body: @escaping @isolated(any) (Input) async -> Output) {
            isolation = body.isolation
            let newBlock: ((Input) async -> UncheckedSendable<Output>) = unsafeBitCast(
                body, to: ((Input) async -> UncheckedSendable<Output>).self)
            self.body = { (a: isolated (Actor)?, input: UncheckedSendable<Input>) async in
                return await newBlock(input.getValue())
            }
        }
        public func callAsFunction(_ value: Input) async -> Output {
            return await self.body(self.isolation, UncheckedSendable(value)).getValue()
        }

        public func unsafeReturn(input: Input) async -> UncheckedSendable<Output> {
            return await body(isolation, UncheckedSendable(input))
        }
    }

    @_allowFeatureSuppression(IsolatedAny)
    public struct AsyncUnsafeThrowingIsolatedClosure<Input, Output>: @unchecked Sendable {
        let body:
            (isolated (any Actor)?, UncheckedSendable<Input>) async throws ->
                UncheckedSendable<Output>
        let isolation: (any Actor)?
        public init(
            @_inheritActorContext body: @escaping @isolated(any) (Input) async throws -> Output
        ) {
            isolation = body.isolation
            let newBlock: ((Input) async throws -> UncheckedSendable<Output>) = unsafeBitCast(
                body, to: ((Input) async throws -> UncheckedSendable<Output>).self)
            self.body = {
                (a: isolated (Actor)?, input: UncheckedSendable<Input>) async throws in
                return try await newBlock(input.getValue())
            }
        }
        public func callAsFunction(_ value: Input) async throws -> Output {
            return try await self.body(self.isolation, UncheckedSendable(value)).getValue()
        }

        public func unsafeReturn(input: Input) async throws -> UncheckedSendable<Output> {
            return try await body(isolation, UncheckedSendable(input))
        }
    }
#else

    public struct UnsafeThrowingIsolatedClosure<Input, Output: Copyable>: @unchecked Sendable {
        let body:
            (UncheckedSendable<Input>) async throws -> UncheckedSendable<
                Output
            >
        public init(@_inheritActorContext body: @escaping (Input) throws -> Output) {
            let newBlock: (Input) throws -> Output = body
            self.body = { (input: UncheckedSendable<Input>) throws in
                return UncheckedSendable(try newBlock(input.getValue()))
            }
        }
        public func callAsFunction(_ value: Input) async throws -> Output {
            return try await self.body(self.isolation, UncheckedSendable(value)).getValue()
        }

        public func unsafeReturn(input: Input) async throws -> UncheckedSendable<Output> {
            return try await body(isolation, UncheckedSendable(input))
        }
    }

    public struct UnsafeIsolatedClosure<Input, Output: Copyable>: @unchecked Sendable {
        let body: (UncheckedSendable<Input>) async -> UncheckedSendable<Output>
        public init(@_inheritActorContext body: @escaping (Input) -> Output) {
            isolation = body.isolation
            let newBlock: (Input) -> Output = body
            self.body = { (input: UncheckedSendable<Input>) in
                return UncheckedSendable(newBlock(input.getValue()))
            }
        }
        public func callAsFunction(_ value: Input) async -> Output {
            return await self.body(self.isolation, UncheckedSendable(value)).getValue()
        }

        public func unsafeReturn(input: Input) async -> UncheckedSendable<Output> {
            return await body(isolation, UncheckedSendable(input))
        }
    }

    public struct AsyncUnsafeIsolatedClosure<Input, Output>: @unchecked Sendable {
        let body:
            (isolated (any Actor)?, UncheckedSendable<Input>) async -> UncheckedSendable<
                Output
            >
        let isolation: (any Actor)?
        public init(@_inheritActorContext body: @escaping (Input) async -> Output) {
            isolation = body.isolation
            let newBlock: ((Input) async -> UncheckedSendable<Output>) = unsafeBitCast(
                body, to: ((Input) async -> UncheckedSendable<Output>).self)
            self.body = { (a: isolated (Actor)?, input: UncheckedSendable<Input>) async in
                return await newBlock(input.getValue())
            }
        }
        public func callAsFunction(_ value: Input) async -> Output {
            return await self.body(self.isolation, UncheckedSendable(value)).getValue()
        }

        public func unsafeReturn(input: Input) async -> UncheckedSendable<Output> {
            return await body(isolation, UncheckedSendable(input))
        }
    }

    public struct AsyncUnsafeThrowingIsolatedClosure<Input, Output>: @unchecked Sendable {
        let body:
            (isolated (any Actor)?, UncheckedSendable<Input>) async throws ->
                UncheckedSendable<Output>
        let isolation: (any Actor)?
        public init(
            @_inheritActorContext body: @escaping (Input) async throws -> Output
        ) {
            isolation = body.isolation
            let newBlock: ((Input) async throws -> UncheckedSendable<Output>) = unsafeBitCast(
                body, to: ((Input) async throws -> UncheckedSendable<Output>).self)
            self.body = {
                (a: isolated (Actor)?, input: UncheckedSendable<Input>) async throws in
                return try await newBlock(input.getValue())
            }
        }
        public func callAsFunction(_ value: Input) async throws -> Output {
            return try await self.body(self.isolation, UncheckedSendable(value)).getValue()
        }

        public func unsafeReturn(input: Input) async throws -> UncheckedSendable<Output> {
            return try await body(isolation, UncheckedSendable(input))
        }
    }

#endif */

public struct UnsafeThrowingIsolatedClosure<Input, Output: Copyable>: @unchecked Sendable {
    let body:
        (UncheckedSendable<Input>) async throws -> UncheckedSendable<
            Output
        >
    public init(@_inheritActorContext body: @escaping (Input) async throws -> Output) {
        let newBlock: (Input) async throws -> Output = body
        self.body = { (input: UncheckedSendable<Input>) async throws in
            return UncheckedSendable(try await newBlock(input.getValue()))
        }
    }
    public func callAsFunction(_ value: Input) async throws -> Output {
        return try await self.body(UncheckedSendable(value)).getValue()
    }

    public func unsafeReturn(input: Input) async throws -> UncheckedSendable<Output> {
        return try await body(UncheckedSendable(input))
    }
}

public struct UnsafeIsolatedClosure<Input, Output: Copyable>: @unchecked Sendable {
    let body: (UncheckedSendable<Input>) -> UncheckedSendable<Output>
    public init(@_inheritActorContext body: @escaping (Input) -> Output) {
        let newBlock: (Input) -> Output = body
        self.body = { (input: UncheckedSendable<Input>) in
            return UncheckedSendable(newBlock(input.getValue()))
        }
    }
    public func callAsFunction(_ value: Input) async -> Output {
        return self.body(UncheckedSendable(value)).getValue()
    }

    public func unsafeReturn(input: Input) async -> UncheckedSendable<Output> {
        return body(UncheckedSendable(input))
    }
}

public struct AsyncUnsafeIsolatedClosure<Input, Output>: @unchecked Sendable {
    let body:
        (UncheckedSendable<Input>) async -> UncheckedSendable<
            Output
        >
    public init(@_inheritActorContext body: @escaping (Input) async -> Output) {
        let newBlock: ((Input) async -> UncheckedSendable<Output>) = unsafeBitCast(
            body, to: ((Input) async -> UncheckedSendable<Output>).self)
        self.body = { (input: UncheckedSendable<Input>) async in
            return await newBlock(input.getValue())
        }
    }
    public func callAsFunction(_ value: Input) async -> Output {
        return await self.body(UncheckedSendable(value)).getValue()
    }

    public func unsafeReturn(input: Input) async -> UncheckedSendable<Output> {
        return await body(UncheckedSendable(input))
    }
}

public struct AsyncUnsafeThrowingIsolatedClosure<Input, Output>: @unchecked Sendable {
    let body:
        (UncheckedSendable<Input>) async throws ->
            UncheckedSendable<Output>
    public init(
        @_inheritActorContext body: @escaping (Input) async throws -> Output
    ) {
        let newBlock: ((Input) async throws -> UncheckedSendable<Output>) = unsafeBitCast(
            body, to: ((Input) async throws -> UncheckedSendable<Output>).self)
        self.body = {
            (input: UncheckedSendable<Input>) async throws in
            return try await newBlock(input.getValue())
        }
    }
    public func callAsFunction(_ value: Input) async throws -> Output {
        return try await self.body(UncheckedSendable(value)).getValue()
    }

    public func unsafeReturn(input: Input) async throws -> UncheckedSendable<Output> {
        return try await body(UncheckedSendable(input))
    }
}

func isolateClosure<A: Actor>(to a: A, _ clos: @escaping () throws -> Void) async rethrows {
    let closure: UnsafeThrowingClosure<(), Void> = UnsafeThrowingClosure(body: clos)
    try await { (a: isolated A) in
        try closure(())
    }(a)
}

func isolateClosure(_ clos: @escaping @isolated(any) () throws -> Void) async rethrows {
    try await { try await UnsafeThrowingIsolatedClosure(body: clos)(()) }()

}

func isolateAsyncClosure<A: Actor>(to a: A? = #isolation, _ clos: @escaping () throws -> Void)
    async rethrows
{
    let closure: UnsafeThrowingClosure<(), Void> = UnsafeThrowingClosure(body: clos)
    try await { (a: isolated A?) in
        try closure(())
    }(a)
}

func isolateAsyncClosure<Input, Output>(
    input: Input, _ clos: @escaping @isolated(any) (Input) throws -> Output
)
    async rethrows -> Output
{
    let closure: AsyncUnsafeThrowingClosure<Input, Output> = AsyncUnsafeThrowingClosure<
        Input, Output
    >(body: clos)
    return try await { return try await closure.unsafeReturn(input: input) }().getValue()
}
