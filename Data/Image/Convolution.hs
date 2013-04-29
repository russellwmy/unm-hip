{-# LANGUAGE ViewPatterns, FlexibleContexts #-}
{-# OPTIONS -O2 #-}
module Data.Image.Convolution(Kernel,
                              Kernel2D,
                              kernel,
                              kernel2d,
                              convolveRows,
                              convolveCols,
                              convolve, convolve',
                              erode, erode', erode'',
                              dilate, dilate', dilate'',
                              open, open', open'',
                              close, close', close'') where

import Data.Array.IArray

import Data.Image.Internal
import Data.Image.Math

type Kernel a = Array Int a
type Kernel2D a = Array (Int, Int) a

kernel :: [a] -> Kernel a
kernel ls = listArray (0, (length ls) - 1) (reverse ls)

kernel2d :: [[a]] -> Kernel2D a
kernel2d ls = listArray ((0,0), (length ls-1, length (head ls) - 1)) (reverse . concat $ ls)
  
convolveRows :: (Image img,
                 Num (Pixel img)) => [Pixel img] -> img -> img
convolveRows = convolveRows' . kernel

convolveRows' :: (Image img, 
                 Num (Pixel img)) => Kernel (Pixel img) -> img -> img
convolveRows' k = convolve' k' where
  k' = listArray ((0,0), (0,cols-1)) ls where
    ls = elems k
    cols = length ls
    
convolveCols :: (Image img,
                 Num (Pixel img)) => [Pixel img] -> img -> img
convolveCols = convolveCols' . kernel

convolveCols' :: (Image img, 
                 Num (Pixel img)) => Kernel (Pixel img) -> img -> img
convolveCols' k = convolve' k' where
  k' = listArray ((0,0), (rows-1,0)) ls where
    ls = elems k
    rows = length ls

convolve :: (Image img,
             Num (Pixel img)) => [[Pixel img]] -> img -> img
convolve = convolve' . kernel2d

convolve' :: (Image img,
             Num (Pixel img)) => Kernel2D (Pixel img) -> img -> img            
convolve' k img@(dimensions -> (rows, cols)) = makeImage rows cols conv where
  conv r c = px where
    imgVal = map (uncurry (periodRef img) . (\ (r', c') -> (r+r', c+c'))) imgIx
    imgIx = map (\ (r, c) -> (r - cR, c - cC)) . indices $ k
    kVal = elems k
    px = sum . map (\ (p,k') -> p*k') . zip imgVal $ kVal
  ((minR, minC), (maxR, maxC)) = bounds k
  cR = (maxR - minR) `div` 2
  cC = (maxC - minC) `div` 2
  recenter = map (\ (r, c) -> ((r-cR), (c-cC))) . indices $ k

periodRef :: (Image img) => img -> Int -> Int -> (Pixel img)
periodRef img@(dimensions -> (rows, cols)) r c = ref img (r `mod` rows) (c `mod` cols)

erode :: (Image img,
          Binary (Pixel img),
          Num (Pixel img),
          Eq (Pixel img)) => img -> img
erode img = (convolve [[1,1],[1,1]] img) .== 4

erode' :: (Image img,
           Binary (Pixel img),
           Num (Pixel img),
           Eq (Pixel img)) => [[Pixel img]] -> img -> img
erode' ls img = (convolve ls img) .== (sum . concat $ ls)

erode'' :: (Image img,
            Binary (Pixel img),
            Num (Pixel img),
            Eq (Pixel img)) => Kernel2D (Pixel img) -> img -> img
erode'' k img = (convolve' k img) .== (sum . elems $ k)

dilate :: (Image img,
           Binary (Pixel img),
           Num (Pixel img),
           Ord (Pixel img)) => img -> img
dilate img = (convolve [[1,1],[1,1]] img) .> 0

dilate' :: (Image img,
           Binary (Pixel img),
           Num (Pixel img),
           Ord (Pixel img)) => [[Pixel img]] -> img -> img
dilate' ls img = (convolve ls img) .> 0

dilate'' :: (Image img,
             Binary (Pixel img),
             Num (Pixel img),
             Ord (Pixel img)) => Kernel2D (Pixel img) -> img -> img
dilate'' k img = (convolve' k img) .> 0

open :: (Image img,
         Binary (Pixel img),
         Num (Pixel img),
         Ord (Pixel img)) => img -> img
open = dilate . erode

open' :: (Image img,
          Binary (Pixel img),
          Num (Pixel img),
          Ord (Pixel img)) => [[Pixel img]] -> img -> img
open' ls = dilate' ls . erode' ls

open'' :: (Image img,
           Binary (Pixel img),
           Num (Pixel img),
           Ord (Pixel img)) => Kernel2D (Pixel img) -> img -> img
open'' k = dilate'' k . erode'' k

close :: (Image img,
          Binary (Pixel img),
          Num (Pixel img),
          Ord (Pixel img)) => img -> img
close = erode . dilate

close' :: (Image img,
           Binary (Pixel img),
           Num (Pixel img),
           Ord (Pixel img)) => [[Pixel img]] -> img -> img
close' ls = erode' ls . dilate' ls


close'' :: (Image img,
            Binary (Pixel img),
            Num (Pixel img),
            Ord (Pixel img)) => Kernel2D (Pixel img) -> img -> img
close'' k img = erode'' k . dilate'' k $ img
