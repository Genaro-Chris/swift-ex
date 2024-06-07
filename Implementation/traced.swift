import SwiftDiagnostics
import SwiftSyntax
import SwiftSyntaxBuilder
@_spi(ExperimentalLanguageFeature) import SwiftSyntaxMacros

@_spi(ExperimentalLanguageFeature)
public struct TracedPreambleMacro: PreambleMacro {
  public static func expansion(
    of node: AttributeSyntax,
    providingPreambleFor declaration: some DeclSyntaxProtocol & WithOptionalCodeBlockSyntax,
    in context: some MacroExpansionContext
  ) throws -> [CodeBlockItemSyntax] {
    // FIXME: Should be able to support (de-)initializers and accessors as
    // well, but this is a lazy implementation.
    guard let funcDecl = declaration.as(FunctionDeclSyntax.self) else {
      return []
    }

    let funcBaseName = funcDecl.name
    let paramNames = funcDecl.signature.parameterClause.parameters.map { param in
      param.parameterName?.text ?? "_"
    }

    let passedArgs = paramNames.map { "\($0): \\(\($0))" }.joined(separator: ", ")

    let entry: CodeBlockItemSyntax = """
      logMsg("Entering \(funcBaseName)(\(raw: passedArgs))")
      """

    let argLabels = paramNames.map { "\($0):" }.joined()

    let exit: CodeBlockItemSyntax = """
      logMsg("Exiting \(funcBaseName)(\(raw: argLabels))")
      """

    return [
      entry,
      """
      defer {
        \(exit)
      }
      """,
    ]
  }
}
