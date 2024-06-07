import SwiftDiagnostics
import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros

public struct UnwrapMacro: CodeItemMacro {
    public static func expansion(
        of node: some FreestandingMacroExpansionSyntax,
        in context: some MacroExpansionContext
    ) throws -> [CodeBlockItemSyntax] {
        [
            .init(
                item: .decl(
                    """

                    struct \(context.makeUniqueName("UnwrapStruct")) {
                      var x: Int
                    }
                    """
                )),
            .init(
                item: .stmt(
                    """

                    if true {
                      print("from stmt")
                    }

                    if false {
                      print("impossible")
                    }
                    """
                )),

            .init(
                item: .expr(
                    """

                    print("from expr")
                    """
                )),
        ]
    }
}
