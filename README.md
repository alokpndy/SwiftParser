# ParSwift

A general purpose parser in Swift.
=======
> Started as JSON parser but can be applied as general Parser and Combinator. 
> I will rewrite this.
---
## Application of Haskell Types, Typeclass etc.

    1. newtype StateT s m a = StateT { runState :: s -> m a } and typealias; type ParserT a = StateT String Maybe a 
    2. Functor, Applicative, Monad, Traversable and Monoid instances of StateT.
## Transcription in Swift 
    1. Applying Generic Swift pattern; struct StateT<S,A>  {..}
    2. Protocols provide aletrnative to TypeClass; protocol Functor {..} etc. 


> find code at: Func.playground/Contents.swift
>>>>>>> 06684c40cdbbb2fbdd4767096eb25cd617e24fe3
