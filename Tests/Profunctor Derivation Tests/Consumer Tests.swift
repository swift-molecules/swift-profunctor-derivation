import Profunctor_Derivation
import Testing

@Profunctor
private struct Function<Input, Output> {
    var call: (Input) -> Output
}

@Test
func `derived dimap transforms both sides`() {
    let length = Function<String, Int> { $0.count }
    let described = length.dimap(
        { (characters: [Character]) in String(characters) },
        { "length=\($0)" }
    )

    #expect(described.call(["B", "l", "o", "b"]) == "length=4")
}
