public import SwiftSyntax
import SwiftSyntaxBuilder

public enum Derivation {
    public static func expansion(of structure: StructDeclSyntax) -> [DeclSyntax] {
        guard
            let generic = structure.genericParameterClause,
            generic.parameters.count == 2
        else { return [] }

        let parameters = Array(generic.parameters)
        let input = parameters[0].name.text
        let output = parameters[1].name.text
        let functions = structure.memberBlock.members
            .compactMap { $0.decl.as(VariableDeclSyntax.self) }
            .flatMap(\.bindings)
            .compactMap { binding -> String? in
                guard
                    let name = binding.pattern.as(IdentifierPatternSyntax.self)?.identifier.text,
                    let function = binding.typeAnnotation?.type.as(FunctionTypeSyntax.self),
                    function.parameters.count == 1,
                    function.parameters.first?.type.trimmedDescription == input,
                    function.returnClause.type.trimmedDescription == output
                else { return nil }
                return name
            }

        guard functions.count == 1 else { return [] }
        let function = functions[0]

        return ["""
            func dimap<MappedInput, MappedOutput>(
                _ mapInput: @escaping (MappedInput) -> \(raw: input),
                _ mapOutput: @escaping (\(raw: output)) -> MappedOutput
            ) -> \(raw: structure.name.text)<MappedInput, MappedOutput> {
                \(raw: structure.name.text)<MappedInput, MappedOutput>(
                    \(raw: function): { mapOutput(self.\(raw: function)(mapInput($0))) }
                )
            }
            """]
    }
}
