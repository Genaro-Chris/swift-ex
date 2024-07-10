import SwiftCompilerPlugin
import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros

extension DeclModifierListSyntax.Element {
    private static let visibility =
        [.public, .private, .internal, .open, .fileprivate] as [Keyword]

    var isVisibilityModifier: Bool {
        if case let .keyword(val) = self/* .as(DeclModifierSyntax.self)? */.name.tokenKind {
            return Self.visibility.contains(val)
        }
        return false
    }
}

public struct DTOMacro: MemberMacro {
    public static func expansion(
        of node: AttributeSyntax,
        providingMembersOf declaration: some DeclGroupSyntax,
        in context: some MacroExpansionContext
    ) throws -> [DeclSyntax] {
        guard
            let modifier = declaration.modifiers.first(where: { m in
                m.isVisibilityModifier
            }).map({ DeclModifierSyntax(name: $0.name.trimmed) })
        else {
            return []
        }
        let blueprint = declaration.memberBlock.members.first { m in
            m.decl.is(StructDeclSyntax.self)
        }?.decl.as(StructDeclSyntax.self)
        var bpMembers =
            blueprint?.memberBlock.members.compactMap { m -> VariableDeclSyntax? in
                m.decl.as(VariableDeclSyntax.self)
            } ?? []
        for i in bpMembers.indices {
            if let mi = bpMembers[i].modifiers.firstIndex(where: { m in
                m.isVisibilityModifier
            }) {
                bpMembers[i].modifiers[mi] = modifier
            } else {
                bpMembers[i].modifiers.append(modifier)
            }
        }
        return bpMembers.map {
            DeclSyntax(fromProtocol: $0)
        }
    }
}
