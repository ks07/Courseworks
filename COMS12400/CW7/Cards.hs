module Cards where

data Suit = Club | Diamond | Heart | Spade
          deriving (Show, Eq, Read, Ord)
                   
data Rank = Ace | Two | Three | Four | Five | Six | Seven |
            Eight | Nine | Ten | Jack | Queen | King
          deriving (Show, Eq, Read, Ord)
                   
data Card = Card Rank Suit
          deriving (Show, Eq, Read, Ord)
                   
display :: Card -> String
display (Card r s) = (show r) ++ " of " ++ (show s) ++ "s"

