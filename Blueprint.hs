module Blueprint where

import Data.List

-- this defines the blueprint types
-- a bluerint is a matrix of blueprint cells, where each cell is either empty
-- or contains something to be done
-- this is now directly represented by chars, but it may bennefit from making this identification
-- abstract with the help of newtype

type Blueprintcell = Maybe Char

data Blueprint = Blueprint {blueprint :: [[Blueprintcell]]}

instance Show Blueprint where
    show = showblueprint . blueprint 

data SymmetryPoint = Topleft | Topmiddle | Topright | Left | Middle | Right |
                     Botleft | Botmiddle | Botright
    deriving (Eq,Show,Read)

blueprintcell2char :: Blueprintcell->Char
blueprintcell2char Nothing   = '#'
blueprintcell2char (Just c)  = c

char2blueprintcell :: Char->Blueprintcell
char2blueprintcell '#' = Nothing
char2blueprintcell c   = Just c

showblueprint :: [[Blueprintcell]]->String
showblueprint = unlines . (map (map blueprintcell2char))

readblueprint :: String->[[Blueprintcell]]
readblueprint = (map (map char2blueprintcell)) . lines

applyToNth :: Int->(a->a)->[a]->[a]
applyToNth n f (x:xs)
    |n==0       = (f x):xs
    |otherwise  = x:(applyToNth (n-1) f xs)  

replaceNth :: Int->a->[a]->[a]
replaceNth n y = applyToNth n (const y)

--blueprint information
blueprintWidth :: Blueprint->Int
blueprintWidth (Blueprint [[]]) = 0
blueprintWidth bp = length $ head $ blueprint bp

blueprintHeight :: Blueprint -> Int
blueprintHeight = length . blueprint 

blueprintElement :: (Int,Int)->Blueprint->Blueprintcell
blueprintElement (n,m) bp = get n $ get m $ blueprint bp 
        where get = flip (!!)

isWallsegment :: (Int,Int)->Blueprint->Bool
isWallsegment (n,m) = (==Nothing).(blueprintElement (n,m))

isWallArea :: (Int,Int)->(Int,Int)->Blueprint->Bool
isWallArea (n1,m1) (n2,m2) bp = all (\(a,b)-> isWallsegment (a,b) bp) [(n,m) |n<-[n1..n2],m<-[m1..m2]]

hasBeds :: Blueprint->Bool
hasBeds = (elem (Just 'B')).concat.blueprint

hasStartingPoint :: Blueprint->Bool
hasStartingPoint = (elem (Just 'S')).concat.blueprint

startCoordinates :: Blueprint->Maybe (Int,Int)
startCoordinates bp 
    |hasStartingPoint bp = Just (value rownumber,value $ elemIndex (Just 'S') (value row))
    |otherwise           = Nothing
    where blueprintList = blueprint bp
          row           = find (elem (Just 'S')) blueprintList
          rownumber     = findIndex (elem (Just 'S')) blueprintList
          value (Just x)= x           
 
--emptyBlueprint

emptyBP :: Int->Int->Blueprint
emptyBP width height = Blueprint $ replicate height (replicate width Nothing)

rectangularRoom :: Int->Int->Blueprint
rectangularRoom width height = Blueprint $ replicate height (replicate width (Just '.'))

--
--blueprint Manipulation
--

vWall :: Int->Blueprint
vWall n = Blueprint $ replicate n [Nothing]  

hWall :: Int->Blueprint
hWall n = Blueprint $ [replicate n Nothing]

vCorridor :: Int->Blueprint
vCorridor n = Blueprint $ replicate n [Just '.']  

hCorridor:: Int->Blueprint
hCorridor n = Blueprint $ [replicate n (Just '.')]

replaceBlueprintCell :: (Int,Int)->Blueprintcell->Blueprint->Blueprint
replaceBlueprintCell (n,m) bpc = Blueprint . (applyToNth n (replaceNth m bpc)) . blueprint 

replaceBlueprintArea :: (Int,Int)->Blueprint->Blueprint->Blueprint
replaceBlueprintArea (n,m) smallbp bigbp = foldl (\bp ((a,b),cell)->replaceBlueprintCell (n+a,m+b) cell bp) bigbp  enumeratedSmallbp
                            where enumeratedSmallbp =[((n,m),cell)|(n,line)<-zip [0..] (blueprint smallbp),(m,cell)<-zip [0..] line]

--sidewise adding
(|||) :: Blueprint->Blueprint->Blueprint
(|||) bp1 bp2 = Blueprint (zipWith (++) (blueprint bp1) (blueprint bp2))

horizontalRepeatBlueprint ::Int->Blueprint->Blueprint
horizontalRepeatBlueprint n bp = foldl1 (|||) (replicate n bp)

--adding with single column wall inbetween
(||^) :: Blueprint->Blueprint->Blueprint
(||^) bp1 bp2 = bp1 ||| (vWall n) |||  bp2
    where n = length $ blueprint bp1

horizontalRepeatBlueprintW ::Int->Blueprint->Blueprint
horizontalRepeatBlueprintW n bp = foldl1 (||^) (replicate n bp)

--topwise adding
(^^^) :: Blueprint->Blueprint->Blueprint
(^^^) bp1 bp2 = Blueprint ((blueprint bp1) ++ (blueprint bp2))

verticalRepeatBlueprint ::Int->Blueprint->Blueprint
verticalRepeatBlueprint n bp = foldl1 (^^^) (replicate n bp)

--adding with single column wall inbetween
(^^|) :: Blueprint->Blueprint->Blueprint
(^^|) bp1 bp2 = bp1 ^^^ (hWall n) ^^^  bp2
    where n = length $ head $ blueprint bp1

verticalRepeatBlueprintW ::Int->Blueprint->Blueprint
verticalRepeatBlueprintW n bp = foldl1 (^^|) (replicate n bp)

--simple wall and corridor adding

addWallLeft :: Blueprint->Blueprint
addWallLeft bp =  (vWall (blueprintHeight bp)) ||| bp

addWallRight:: Blueprint->Blueprint
addWallRight bp = bp ||| (vWall (blueprintHeight bp))

addCorridorLeft:: Blueprint->Blueprint
addCorridorLeft bp =  (vCorridor (blueprintHeight bp)) ||| bp

addCorridorRight:: Blueprint->Blueprint
addCorridorRight bp = bp ||| (vCorridor (blueprintHeight bp))

addWallTop:: Blueprint->Blueprint
addWallTop bp =  (hWall (blueprintWidth bp)) ^^^  bp

addWallBot:: Blueprint->Blueprint
addWallBot bp = bp ^^^ (hWall (blueprintWidth bp))

addCorridorTop:: Blueprint->Blueprint
addCorridorTop bp =  (hCorridor (blueprintWidth bp)) ^^^ bp

addCorridorBot :: Blueprint->Blueprint
addCorridorBot bp = bp ^^^ (hCorridor (blueprintWidth bp))

--mirror
horizontalMirror :: Blueprint->Blueprint
horizontalMirror = Blueprint . reverse . blueprint

verticalMirror :: Blueprint->Blueprint
verticalMirror = Blueprint . (map reverse) . blueprint 

pointMirror :: Blueprint -> Blueprint
pointMirror = horizontalMirror . verticalMirror

--rotation

rotate90 :: Blueprint->Blueprint
rotate90 = horizontalMirror . Blueprint . transpose . blueprint


--joining Corridors
joinCorridorHorizontal:: Int->Blueprint->Blueprint->Blueprint
joinCorridorHorizontal width bp1 bp2 = let corridor = Blueprint $ (replicate (width) (replicate ((length $ head $ blueprint bp1)) (Just '.')))
                                       in bp1 ^^^ corridor ^^^ bp2

repeatedMirroredCorridor :: Int->Int->Blueprint->Blueprint
repeatedMirroredCorridor n corridorwidth bp = let bp1 = (horizontalRepeatBlueprintW n bp)
                                                  bp2 = horizontalMirror bp1
                                              in joinCorridorHorizontal corridorwidth bp1 bp2

joinCorridorVertical:: Int->Blueprint->Blueprint->Blueprint
joinCorridorVertical width bp1 bp2 = let corridor = Blueprint $ (replicate (length $ blueprint bp1) (replicate width (Just '.')))
                                     in bp1 ||| corridor ||| bp2

repeatedMirroredCorridorVertical :: Int->Int->Blueprint->Blueprint
repeatedMirroredCorridorVertical n corridorwidth bp = let bp1 = (verticalRepeatBlueprintW n bp)
                                                          bp2 = verticalMirror bp1
                                                      in joinCorridorVertical corridorwidth bp1 bp2

--fourfold repetition

fourfold :: Blueprint->Blueprint
fourfold bp = let n = blueprintWidth bp
                  m = blueprintHeight bp 
                  background = emptyBP (n+m) (n+m)
              in replaceBlueprintArea (0,0) bp $
                 replaceBlueprintArea (m,0) (rotate90 bp) $ 
                 replaceBlueprintArea (n,m) (rotate90 $ rotate90 bp) $
                 replaceBlueprintArea (0,n) (rotate90$ rotate90 $ rotate90 bp) $
                 replaceBlueprintArea (m,m) (rectangularRoom (n-m) (n-m))
                 background

--setting a starting point for the script
--starting points can automatically be placed at 9 different positions
--which are the symmetry points of the rectangel
--SWWWWWSWWWWWS
--W           W
--S     S     S
--W           W
--SWWWWWSWWWWWS

symmetryPointCoordinates::SymmetryPoint->Blueprint->(Int,Int)
symmetryPointCoordinates sp bp
    |sp==Topleft        = (0,0)
    |sp==Topmiddle      = (n `div` 2,0)
    |sp==Topright       = (n,0)
    |sp==Blueprint.Left = (0,m `div` 2)
    |sp==Middle         = (n `div` 2,m `div` 2)
    |sp==Blueprint.Right= (n,m `div` 2)
    |sp==Botleft        = (0,m)
    |sp==Botmiddle      = (n `div` 2,m)
    |sp==Botright       = (n,m)
        where n = blueprintWidth bp
              m = blueprintHeight bp

addStartingPoint :: SymmetryPoint->Blueprint->Blueprint
addStartingPoint sp bp = replaceBlueprintCell (symmetryPointCoordinates sp bp) (Just 'S') bp

--examples
exampleBedroom = Blueprint [[Just 'H',Just 'F'],[Just '.',Just 'B'],[Just 'D', Nothing]]

tenBedrooms    = let fiveBeds = horizontalRepeatBlueprintW 5 exampleBedroom
                 in joinCorridorHorizontal 1 fiveBeds (horizontalMirror fiveBeds)

thirtyBedrooms =  verticalRepeatBlueprint 3 tenBedrooms
 
lineBedroom = Blueprint [[Just '.'],[Just 'B'],[Just 'H'],[Just 'F'],[Just 'D']]
