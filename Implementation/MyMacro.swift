import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros

struct ThrowsToResult: PeerMacro {
    static func expansion(
        of node: SwiftSyntax.AttributeSyntax,
        providingPeersOf declaration: some SwiftSyntax.DeclSyntaxProtocol,
        in context: some SwiftSyntaxMacros.MacroExpansionContext
    ) throws -> [SwiftSyntax.DeclSyntax] {

        guard let funcDecl = declaration.as(FunctionDeclSyntax.self) else {
            throw CustomError.message("@throwsToResult only works on functions")
        }

        guard funcDecl.signature.effectSpecifiers?.throwsSpecifier != nil else {
            throw CustomError.message("@throwsToResult only works on throwing functions")
        }

        let returnType = funcDecl.signature.returnClause?.type.with(\.leadingTrivia, []).with(
            \.trailingTrivia, [])

        let newAttributeList = funcDecl.attributes.filter { attr in
            guard case let .attribute(attribute) = attr,
                let attributeType = attribute.attributeName.as(IdentifierTypeSyntax.self),
                let nodeType = node.attributeName.as(IdentifierTypeSyntax.self)
            else {
                return true
            }

            return attributeType.name.text != nodeType.name.text
        }

        guard case let .argumentList(arguments) = node.arguments,
            let firstElement = arguments.first,
            let first_Name = firstElement.expression.as(StringLiteralExprSyntax.self),
            case let .stringSegment(segments) = first_Name.segments.first
        else {
            throw CustomError.message("@addCompletionHandler arguments error")
        }

        let callArguments: [String] = funcDecl.signature.parameterClause.parameters.map { param in
            let argName = param.secondName ?? param.firstName

            let paramName = param.firstName
            if paramName.text != "_" {
                return "\(paramName.text): \(argName.text)"
            }

            return "\(argName.text)"
        }
        let hasAsync = funcDecl.signature.effectSpecifiers?.asyncSpecifier != nil

        let funcDeclType = funcDecl.signature.returnClause?.type.with(
            \.leadingTrivia, []
        ).with(\.trailingTrivia, [])

        let body: ExprSyntax =
            hasAsync
            ? """
                print("\(raw: segments.content.text)")
                do {
                    let result: \(funcDeclType ?? "()") = try await \(raw: funcDecl.name)(\(raw: callArguments.joined(separator: ", ")))
                    return .success(result)
                } catch {
                    return .failure(error)
                }
            """
            : """

                do {
                    let result = try \(raw: funcDecl.name)(\(raw: callArguments.joined(separator: ", ")))
                    return .success(result)
                } catch {
                    return .failure(error)
                }
            """

        let parameterList = funcDecl.signature.parameterClause.parameters

        let newfuncDecl =
            funcDecl
            .with(\.name, TokenSyntax(stringLiteral: funcDecl.name.text + "_throws"))
            .with(\.attributes, newAttributeList).with(
                \.signature,
                funcDecl.signature.with(
                    \.effectSpecifiers,
                    FunctionEffectSpecifiersSyntax(
                        asyncSpecifier: hasAsync ? TokenSyntax.identifier("async") : nil,
                        throwsSpecifier: nil)
                ).with(
                    \.parameterClause,
                    funcDecl.signature.parameterClause.with(\.parameters, parameterList)
                        .with(\.trailingTrivia, [])
                )
                .with(
                    \.returnClause,
                    ReturnClauseSyntax(
                        type: TypeSyntax(
                            "Result<\(raw: returnType?.description ?? "()"), Error>")))

            ).with(
                \.body,
                CodeBlockSyntax(
                    leftBrace: .leftBraceToken(),
                    statements: CodeBlockItemListSyntax([CodeBlockItemSyntax(item: .expr(body))]),
                    rightBrace: .rightBraceToken(),
                    trailingTrivia: .newlines(2)))

        //let parametersList = funcDecl.signature.parameterClause

        return [
            DeclSyntax(newfuncDecl)
        ]
    }

}
