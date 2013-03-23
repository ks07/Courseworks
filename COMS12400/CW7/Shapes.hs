module Shapes where

data Point = Point Double Double
           deriving (Show, Eq, Read)

x :: Point -> Double
x (Point x y) = x

y :: Point -> Double
y (Point x y) = y

data Shape =
  Circle Point Double |
  Rectangle Point Point |
  Triangle Point Point Point
  deriving (Show, Eq, Read)
  
area :: Shape -> Double
area (Circle cen rad) = pi * rad * rad
area (Rectangle nw se) = (x se - x nw) * (y se - y nw)
area (Triangle a b c) =
  abs ((((x a) * ((y b) - (y c))) + ((x b) * ((y c) - (y a))) + ((x c) * ((y a) - (y b)))) / 2)

box :: Shape -> Shape
box (Rectangle nw se) = Rectangle nw se
box (Circle cen rad) =
  let nwx = (x cen) - rad
      nwy = (y cen) - rad
      sex = (x cen) + rad
      sey = (y cen) + rad
  in  Rectangle (Point nwx nwy) (Point sex sey)
box (Triangle a b c) =
  let nwx = minimum [x a, x b, x c]
      nwy = minimum [y a, y b, y c]
      sex = maximum [x a, x b, x c]
      sey = maximum [y a, y b, y c]
  in  Rectangle (Point nwx nwy) (Point sex sey)

centre :: Shape -> Point
centre (Rectangle a b) = Point (((x b - x a) / 2) + x a) (((y b - y a) / 2) + y a)
centre (Circle cent r) = cent
centre (Triangle a b c) =
  let cx = (x a + x b + x c) / 3
      cy = (y a + y b + y c) / 3
  in  Point cx cy