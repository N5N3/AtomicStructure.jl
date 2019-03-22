# * Orbital equation

"""
    AtomicOrbitalEquation(atom, equation, orbital, ϕ, hamiltonian)

Governs the evolution of an atomic `orbital` belonging to an
`atom`. `equation` is the symbolic expression, from which
`hamiltonian` is constructed. `ϕ` is the `QuasiVector` representing
the radial orbital.
"""
mutable struct AtomicOrbitalEquation{T, B<:Basis,
                                     O<:AbstractOrbital,
                                     A<:Atom{T,B,O},
                                     Equation,
                                     M# <:OrbitalHamiltonian{T,B,O}
                                     }
    atom::A
    equation::Equation
    orbital::O
    ϕ::RadialOrbital{T,B}
    hamiltonian::M
end

SCF.hamiltonian(hfeq::AtomicOrbitalEquation) = hfeq.hamiltonian

function AtomicOrbitalEquation(atom::A, equation::Equation, orbital::O,
                               terms::Vector{<:OrbitalHamiltonianTerm{O,T,B}},
                               symmetry_orbitals::Vector{O}) where {T,
                                                                    B<:Basis,
                                                                    O<:AbstractOrbital,
                                                                    A<:Atom{T,B,O},
                                                                    Equation}
    OV = typeof(view(atom,orbital))
    projector = Projector(OV[view(atom, other)
                             for other in symmetry_orbitals])

    hamiltonian = OrbitalHamiltonian(radial_basis(atom), terms,
                                     atom.mix_coeffs, projector, orbital)

    AtomicOrbitalEquation(atom, equation, orbital, view(atom, orbital), hamiltonian)
end

"""
    SCF.energy(hfeq::AtomicOrbitalEquation[, which=:total])

Compute the orbital energy for the orbital governed by
`hfeq`. Optionally select which contribution is computed (`:total`,
`:onebody`, `:direct`, or `:exchange`).
"""
SCF.energy(hfeq::AtomicOrbitalEquation, which::Symbol=:total) =
    materialize(applied(*, hfeq.ϕ', hfeq.hamiltonian[which], hfeq.ϕ))

function Base.show(io::IO, hfeq::AtomicOrbitalEquation)
    EHa = energy(hfeq)
    write(io, "⟨$(hfeq.orbital)| 𝓗 |$(hfeq.orbital)⟩ = $(EHa) Ha = $(27.211EHa) eV")
end

function Base.show(io::IO, ::MIME"text/plain", hfeq::AtomicOrbitalEquation)
    write(io, "Hartree–Fock equation: E|$(hfeq.orbital)⟩ = ")
    show(io, hfeq.equation)
    write(io, "\n")
    show(io, hfeq)
    write(io, "\n")
end

import SCF: energy
export energy
