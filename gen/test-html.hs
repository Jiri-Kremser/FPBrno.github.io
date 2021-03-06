{-# LANGUAGE OverloadedStrings #-}
import qualified Text.Blaze.Html5 as H
import qualified Text.Blaze.Html5.Attributes as A
import qualified Text.Blaze.Html.Renderer.String as R
-- import qualified Text.Blaze.Html.Renderer.Pretty as R

import Data.List (intersperse)
import Data.Monoid
import Data.Time
import Data.Time.ISO8601 (formatISO8601)

data Presentation = Presentation
    { title :: String
    , author :: String
    , slides :: Maybe String
    , audio :: Maybe String
    , player :: Maybe String
    } deriving Show

data Meetup = Meetup
    { indexM :: Integer
    , presentations :: [Presentation]
    , time :: UTCTime
    , participants :: Integer
    } deriving Show

meetups :: [Meetup]
meetups =
    [ Meetup
        { indexM = 0
        , presentations =
            [ Presentation
                { title = "There is no Compiler"
                , author = "Matej"
                , slides = Just "fpb-0/fpb-0.html"
                , audio = Just "fpb-0/fpb-0.ogg"
                , player = Just "fpb-0/player.html"
                }
            ]
        , time = read "2015-02-16 19:00:00 CET"
        , participants = 6
        }
    ]

time2Html :: UTCTime -> H.Html
time2Html t = H.time H.! A.class_ "timeago" H.! A.datetime (H.toValue $ formatISO8601 t) $ H.toHtml (show t)

mFromMaybe_ :: Monad m => (a -> m ()) -> Maybe a -> m ()
mFromMaybe_ = maybe (return ())

presentation2html :: Presentation -> H.Html
presentation2html p = H.div H.! A.class_ "presentation" $ do
    H.toHtml (title p)
    " (by "
    H.toHtml (author p)
    ")"
    H.div H.! A.class_ "pres_goodies" $ do
        h "Slides" slides
        h "Audio" audio
        h "Player" player
    where
    g t u = H.a H.! A.href (H.toValue u) $ t
    h a b = mFromMaybe_ (g a) (b p)

presentations2html :: [Presentation] -> H.Html
presentations2html [] = "No presentations"
presentations2html [x] = do
    "Presentation: "
    presentation2html x
presentations2html s = do
    "Presentatios: "
    mapM_ presentation2html s

meetup2html :: Meetup -> H.Html
meetup2html x = H.div H.! A.class_ "meetup" $ do
    H.h3 . H.toHtml $ "Meetup " ++ show (indexM x)
    H.ul $ do
        H.li $ do
            "Time: "
            time2Html $ time x
        H.li ("Participants: " >> H.toHtml (show $ participants x))
        H.li $ presentations2html (presentations x)

fpbTitle :: H.Html
fpbTitle = "Functional Programming Brno"

cdns :: H.Html
cdns = mconcat
    [ js "https://code.jquery.com/jquery-2.1.3.min.js"
    , js "https://cdn.rawgit.com/rmm5t/jquery-timeago/master/jquery.timeago.js"
    ] where
        css u = H.link H.! A.rel "stylesheet" H.! A.href u
        js  u = H.script H.! A.src u $ mempty

timeago :: H.Html
timeago = H.script . H.preEscapedToHtml $ ("jQuery(document).ready(function(){jQuery(\"time.timeago\").timeago();});" :: String)

site :: H.Html
site = H.html $ do
    H.head $ do
        H.meta H.! A.charset "UTF-8"
        H.title H.! A.class_ "head-title" $ fpbTitle
        H.link H.! A.rel "stylesheet" H.! A.type_ "text/css" H.! A.href "style.css"
        cdns
        timeago
    H.body $ H.div H.! A.class_ "wrapper" $ do
        H.header $ do
            H.h1 fpbTitle
            H.img H.! A.src "images/FPB.svg" H.! A.alt "Functional Programming Brno"
        H.div H.! A.class_ "main" $ do
            H.p . mconcat $ intersperse " "
                [ "Functional Programming Brno (FPBrno or FPB for short) is for all people with interest in functional programming that happen to be in Brno (https://goo.gl/maps/MIRi3) or nearby areas."
                , "Activities include but are not limited to talks and discussions."
                ]
            H.p "More to come."
            H.h2 "Upcoming events"
            H.p "There are no planned events now. In the ideal case next meetup will occur between 1 and 2 months after the last meetup."
            H.h2 "Past events"
            mapM_ meetup2html . take 10 $ reverse meetups
        H.footer $ do
            H.a H.! A.href "https://github.com/FPBrno" $ "FPBrno on GitHub"
            H.div "© 2015 Functional Programming Brno"

main :: IO ()
main = writeFile "index.html" . R.renderHtml $ H.docType >> site
