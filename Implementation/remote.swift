import SwiftDiagnostics
import SwiftSyntax
import SwiftSyntaxBuilder
@_spi(ExperimentalLanguageFeature) import SwiftSyntaxMacros

extension String: @retroactive Error {}

@_spi(ExperimentalLanguageFeature)
public struct RemoteMacro: BodyMacro {
    public static func expansion(
        of node: AttributeSyntax,
        providingBodyFor declaration: some DeclSyntaxProtocol & WithOptionalCodeBlockSyntax,
        in context: some MacroExpansionContext
    ) throws -> [CodeBlockItemSyntax] {
        guard let funcDecl = declaration.as(FunctionDeclSyntax.self) else {
            return []
        }
        guard funcDecl.signature.effectSpecifiers?.asyncSpecifier != nil else {
            throw "Can not use this macro on a non async function"
        }
        let funcBaseName = funcDecl.name.text
        let parameterNames = funcDecl.signature.parameterClause.parameters.map {
            $0.parameterName ?? TokenSyntax(.wildcard, presence: .present)
        }
        let passedArgs =
            parameterNames.isEmpty
            ? DictionaryExprSyntax()
            : DictionaryExprSyntax(
                content: .elements(
                    DictionaryElementListSyntax {
                        for parameterName in parameterNames {
                            DictionaryElementSyntax(
                                key: ExprSyntax("\(literal: parameterName.text)"),
                                value: DeclReferenceExprSyntax(baseName: parameterName))
                        }
                    }))
        return [
            """
            return await remoteCall(function: \(literal: funcBaseName), arguments: \(passedArgs))
            """
        ]
    }
}

extension FunctionParameterSyntax {
    var parameterName: TokenSyntax? {
        if let secondName {
            if secondName.text == "_" {
                return nil
            }
            return secondName
        }

        if firstName.text == "_" {
            return nil
        }
        return firstName
    }
}
