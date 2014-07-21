{-# LANGUAGE RecordWildCards #-}

module Graphics.DynamicGraph.Axis where

import Control.Monad
import Data.Colour.RGBSpace
import Data.Colour.SRGB
import Data.Colour.Names
import Graphics.Rendering.Cairo
import Graphics.Rendering.Pango

data Configuration = Configuration {
    width           :: Double,
    height          :: Double,
    topMargin       :: Double,
    bottomMargin    :: Double,
    leftMargin      :: Double,
    rightMargin     :: Double,

    backgroundColor :: Colour Double,
    axisColor       :: Colour Double,
    axisWidth       :: Double,
    xGridConfig     :: Maybe GridConfig,
    yGridConfig     :: Maybe GridConfig
}

data GridConfig = GridConfig {
    gridColor   :: Colour Double,
    gridWidth   :: Double,
    gridDash    :: [Double],
    gridOffset  :: Double,
    gridSpacing :: Double,
    gridLabels  :: [String],
    textColor   :: Colour Double
}

defaultXGridConfig = GridConfig {..}
    where
    gridColor   = gray
    gridWidth   = 0.5
    gridDash    = []
    gridOffset  = 50
    gridSpacing = 100
    gridLabels  = ["l1", "l2", "l3", "l4", "l5", "l6"]
    textColor   = white

defaultYGridConfig = GridConfig {..}
    where
    gridColor   = gray
    gridWidth   = 0.5
    gridDash    = [3, 1.5]
    gridOffset  = 0
    gridSpacing = 50
    gridLabels  = ["l1", "l2", "l3", "l4", "l5", "l6"]
    textColor   = white

defaultConfiguration = Configuration {..}
    where
    width           = 500
    height          = 500
    topMargin       = 50
    bottomMargin    = 50
    leftMargin      = 50
    rightMargin     = 50

    backgroundColor = black
    axisColor       = lightgray
    axisWidth       = 1
    xGridConfig     = Just defaultXGridConfig
    yGridConfig     = Just defaultYGridConfig

whenMaybe :: (Functor m, Monad m) => Maybe a -> (a -> m b) -> m ()
whenMaybe mb func = maybe (return ()) (void . func) mb

-- Make a pango layout, fill it with text and return its extents
makeLayout :: PangoContext -> String -> Render (PangoLayout, PangoRectangle)
makeLayout ctx text = liftIO $ do
    layout <- layoutEmpty ctx
    layoutSetMarkup layout text
    (_, rect) <- layoutGetExtents layout
    return (layout, rect)

layoutTopCentre :: PangoContext -> String -> Double -> Double -> Render ()
layoutTopCentre ctx text x y = do
    (layout, PangoRectangle _ _ w _) <- makeLayout ctx text
    moveTo (x - w/2) y
    showLayout layout

layoutRightCentre :: PangoContext -> String -> Double -> Double -> Render ()
layoutRightCentre ctx text x y = do
    (layout, PangoRectangle _ _ w h) <- makeLayout ctx text
    moveTo (x - w) (y - h/2)
    showLayout layout

blankCanvas :: Colour Double -> Double -> Double -> Render ()
blankCanvas colour width height  = do
    uncurryRGB setSourceRGB (toSRGB colour)
    rectangle 0 0 width height
    fill

drawAxes :: Configuration -> Render ()
drawAxes Configuration{..} = do
    setLineCap  LineCapRound
    setLineJoin LineJoinRound
    setLineWidth axisWidth
    uncurryRGB setSourceRGB (toSRGB axisColor)

    --Y axis
    moveTo leftMargin topMargin
    lineTo leftMargin (height - bottomMargin)
    stroke

    --X axis
    moveTo leftMargin (height - bottomMargin)
    lineTo (width - rightMargin) (height - bottomMargin)
    stroke

renderAxes c@Configuration{..} = do
    blankCanvas backgroundColor width height
    drawAxes c

    ctx <- liftIO $ cairoCreateContext Nothing

    --X grid
    whenMaybe xGridConfig $ \GridConfig{..} -> do
        forM (zip gridLabels $ takeWhile (< (width - rightMargin)) $ iterate (+ gridSpacing) (gridOffset + leftMargin)) $ \(label, xCoord) -> do
            --grid lines
            uncurryRGB setSourceRGB (toSRGB gridColor)
            setLineWidth gridWidth
            setDash gridDash 0
            moveTo xCoord (height - bottomMargin)
            lineTo xCoord topMargin
            stroke

            --axis labels
            uncurryRGB setSourceRGB (toSRGB textColor)
            layoutTopCentre ctx label xCoord (height - bottomMargin)

    --Y grid
    whenMaybe yGridConfig $ \GridConfig{..} -> do
        forM (zip gridLabels $ takeWhile (> topMargin) $ iterate (flip (-) gridSpacing) (height - bottomMargin - gridOffset)) $ \(label, yCoord) -> do
            --grid lines
            uncurryRGB setSourceRGB (toSRGB gridColor)
            setLineWidth gridWidth
            setDash gridDash 0
            moveTo (width - rightMargin) yCoord
            lineTo leftMargin yCoord
            stroke

            --axis labels
            uncurryRGB setSourceRGB (toSRGB textColor)
            layoutRightCentre ctx label 50 yCoord

