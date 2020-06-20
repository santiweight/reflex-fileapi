{-# LANGUAGE PackageImports #-}
{-# LANGUAGE RankNTypes #-}
{-# LANGUAGE OverloadedStrings #-}
{-# LANGUAGE ScopedTypeVariables #-}
module Main where

import                            Prelude hiding (head)
import           "lens"           Control.Lens
import           "data-default"   Data.Default (def)
import           "aeson"          Data.Aeson (toJSON)
import           "text"           Data.Text (Text)
import qualified "text"           Data.Text as T (lines, splitOn)
import           "reflex-dom"     Reflex.Dom
import           "reflex-utils"   Reflex.Utils
import           "reflex-jexcel"  Reflex.JExcel
import           "reflex-fileapi" Reflex.FileAPI.FileAPI

--
main :: IO ()
main = mainWidget main_
    where
        main_ :: forall t m. MonadWidget t m => m ()
        main_ = do
            headD <- head
            whenLoaded [headD] blank body
            return ()

--
head :: forall t m. MonadWidget t m => m (Dynamic t Bool)
head = do
    s1Ds <- sequence [ script "https://bossanova.uk/jsuites/v2/jsuites.js"
                     , css    "https://bossanova.uk/jsuites/v2/jsuites.css"
                     ]
    whenLoaded s1Ds blank $ do
        s2Ds <- sequence [ script "https://bossanova.uk/jexcel/v3/jexcel.js"
                         , css    "https://bossanova.uk/jexcel/v3/jexcel.css"
                         ]
        whenLoaded s2Ds blank blank
        return ()

--
body :: MonadWidget t m => m ()
body = do
    -- button triggers everything
    clickE  <- button "Load"

    -- filereader is triggered by clickE
    fileChunkTextE <- filereader "files[]" stepSize clickE

    -- csvE :: Event t [[Text]]
    let csvE = (map (T.splitOn ",") . T.lines) <$> fileChunkTextE
    csvD <- holdDyn [] csvE

    -- spreadsheet
    let jexcelD = buildJExcel <$> csvD
    _ <- jexcel (JExcelInput "excel1" jexcelD)

    -- text display
    display csvD

    return ()
    where
        stepSize :: Int
        stepSize = 10000000 -- bytes

        headerToColumn :: Text -> JExcelColumn
        headerToColumn name
            = def
            & jExcelColumn_title ?~ name

        buildJExcel :: [[Text]] -> JExcel
        buildJExcel [] = def
        buildJExcel (headers:rows)
            = def
            & jExcel_columns    ?~ map headerToColumn headers
            & jExcel_data       ?~ rows
