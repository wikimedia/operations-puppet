--   Copyright (C) 2020 Arturo Borrero Gonzalez <aborrero@wikimedia.org>
--
--  This program is free software: you can redistribute it and/or modify
--  it under the terms of the GNU General Public License as published by
--  the Free Software Foundation, either version 3 of the License, or
--  (at your option) any later version.
--
--  This program is distributed in the hope that it will be useful,
--  but WITHOUT ANY WARRANTY; without even the implied warranty of
--  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
--  GNU General Public License for more details.
--
--  You should have received a copy of the GNU General Public License
--  along with this program.  If not, see <https://www.gnu.org/licenses/>.
--

--- Helper function to build the set of strings
-- @param list List of strings
function Set(list)
   local set = {}
   for _, l in ipairs(list) do set[l] = true end
   return set
end

--- Check the tool is allowed to have a redirect
-- @param toolname Name of the tool
function toolname_allowed(toolname)
    -- static list of allowed tools. To generate this list, see:
    -- https://wikitech.wikimedia.org/wiki/User:Arturo_Borrero_Gonzalez#wmcs-generate-legacy-redirector-list.py
    local allowed = Set {
        'abbe98tools','abbreviso','abricot','account-creator','ace2018',
        'actrial','adas','add','add-information','addshore',
        'admin','admin-beta','afdstats','afrobot','ahechtbot',
        'aiko-citationhunt','aivanalysis','alberobot','alex','algo-news',
        'alphatest','alvaro','ameisenbot','anagrimes','analytics',
        'andrewtesttool','android-maven-repo','anno','anomiebot','anon',
        'anticompositetools','antigng-bot','apersonbot','apps-gallery','apt-browser',
        'archivesearch','archiving','arkivbot','article','article-ideas-generator',
        'articlerequest','articlerequest-dev','articles-by-lat-lon-without-images','articles-needing-links','artlist',
        'artuploader','as-info','as-info-dev','ash-dev','ash-django',
        'ashotbot','assessor','aswnbot','atiro','ato',
        'audetools','author-disambiguator','authors','autodesc','autolist',
        'autometrics','awb','awmd-stats','bambots','base-encode',
        'base-php-cli','basebot','bash','bawolff','bays',
        'bd808-k8smigrate','bd808-ruby','bd808-test','bd808-test2','bennofsplay',
        'betabot','betacommand-dev','bikeshed','bing-maps','blahma',
        'blankpages','bldrwnsch','blockyquery','blog','blubber',
        'book2scroll','bookreader','booster','botriconferme','botwatch',
        'botwikiawk','bsaut','bstorm-tool','bstorm-tool2','bub2',
        'catcompare','category-by-uploaders','catfood','catgraph','catgraph-jsonp',
        'catmonitor','catnap','cats-php','catscan2','ccm',
        'cdnjs','cdnjs-beta','cewbot','charttableconverter','checkdictation-fa',
        'checker','checkpersondata','checkwiki','chie-bot','churches',
        'ci','cil2','citation-bot','citation-template-filling','citationhunt',
        'citations','cite-o-meter','cite-web-helper','citer','citing-bot',
        'cleanup','clpo13-flask','cluebotng','cobot','coh',
        'commons-aiuser','commons-android-app','commons-app-stats','commons-coverage','commons-delinquent',
        'commons-maintenance-bot','commons-mass-description','commons-mass-description-test','commons-poty','commons-video-clicks',
        'commonsarchive','commonscategorycount','commonsedge','commonshelper','commonsinterwiki',
        'completer','comprende','contact','contentcontributor','contraband',
        'contrabandapp','contribgraph','convert','coord','copypatrol',
        'copyvios','corhist','costar','coursestats','coverage',
        'coverme','covid-obit','cpb','cradle','crocodylia',
        'croptool','crossactivity','csfd','csp-report','cssk',
        'currentevents','cvrminer','dapete-dev','data-design-demo','datacon-schedule-app',
        'dataviz','dawikitool','db','dbreps','deadlinkfinder',
        'deadlinks','delinker','denkmalliste','depiction-game','depicts',
        'derivative','deskana','devys','dewikinews-rss','dewkin',
        'dexbot','dibot','dicompte','digitaltmuseum','dimastbkbot',
        'dioceses','dispenser','dixtosa','dna','dnbtools',
        'docker-registry','dockerregistry','douglasbot','dow','dplbot',
        'draftifyhistory','dschwenbot','dspull','dtz','dump-torrents',
        'dumpcattree','dupdet','duplicate-coords','durl-shortener','dykautobot',
        'dykfeed','earwig-dev','earwigbot','eathom','ebraminio-dev',
        'edgars','editathonstat','editgroups','embeddeddata','enet',
        'enwnbot','enwp10','eranbot','erwin85','etytree',
        'event-streams','everythingisconnected','exambot','excel2wiki','externalitemsuggester',
        'extreg-wos','fab-proxy','facebook-messenger-chatbot','faces','family',
        'farhangestan','fastilybot-reports','fatameh','fatemi','fawikiauto',
        'featured-article','fengtools','file-reuse','file-reuse-piwik','file-reuse-test',
        'file-siblings','filedupes','findit','fireflytools','firmenbuch',
        'first-paragraph-readability','fist','five-million','fiwiki-tools','flaggedrevspromotioncheck',
        'flickr2commons','flickrdash','flossbrowser','fontcdn','forrestbot',
        'fountain','fountain-test','fourohfour','freddy2001','freebase',
        'freefiles','fscbot','ft','ftl','ftools',
        'fvcbot','gabrielchihonglee-bot','gallery','genealogy','genedb',
        'geocommons','geodata','geograph2commons','geohack','gerakitools',
        'germancon-mobile','germancontributioncounts','gerrit-patch-uploader','gerrit-reviewer-bot','ggu',
        'giftbot','github-notif-bot','github-pr-closer','glam2commons','glamingest',
        'glamtools','global-pandas','global-search','global-search-test','global-wiki-tools',
        'globalcsd','globalprefs','globalsearch','globalusagecount','gmt',
        'goodarticlebot','google-drive-photos-to-commons','grantmetrics','grantmetrics-test','gratitude',
        'grep','gridengine-status','gsoc','gsoc-petscan-query-articles','gsoc-worklist-tool',
        'gtirloni-sandbox','guc','gurmukhispell','gyan','h2bot',
        'hamishbot','hartman','harvesting-data-refinery','hashtags','hashtags-hub',
        'hashtags-test','hasteurbot','hatjitsu','hauki','hay',
        'hd','hennalabs','herculebot','heritage','hewiki-tools',
        'hgztools','himo','historicmaps','histsearch','holidays-viewer',
        'hoo','hroest','hsfbot','hub','huggle',
        'ia-upload','iabot','ib2test','icalendar','icommons',
        'icu-transliterate','ifttt','ifttt-dev','ifttt-testing','igloo',
        'iluvatarbot','imagechecker','imagemapedit','import-500px','inactiveadmins',
        'incolabot','indic-ocr','indic-techcom','indic-techcom-wiki','indic-wscontest',
        'indic-wsstats','indicwiki','inkpen','integraality','intelibot',
        'interaction-timeline','interactoa','intersect-contribs','intuition','ios-crashes',
        'ip-range-calc','ipchanges','ipcheck','ipcheck-dev','ipwatcher',
        'ipython','ircredirect','ircredirector','isa','isbn',
        'isbn-tmptest','isbn-usage','isbn2wiki','isin','isprangefinder',
        'it-wiki-users-leaflet','itsource','itwiki','itwikinews-rss','jackbot',
        'james','jarry-common','javatest','jayprakashbot','jeh-dev',
        'jembot','jimmy','jitrixis-test','joanjoc','jogobot',
        'jogotools','joinedventure','jorobot','jshint','jtools',
        'jury','kaleem-bot','kaleem-bot-i','kasper-data-translator','khanamalumat',
        'khanomalumat','kian','kmlexport','knowledgegrapher','kokolores',
        'krdbot','krinkle-redirect','ksamsok-rest','lahitools','langviews',
        'langviews-test','ldap','lestaty','lexeme-forms','lexeme-senses',
        'liangent-misc','limesmap','linedwell','lingua-libre','linkscount',
        'linksearch','linkspam','linkstranslator','list','listeria',
        'listpages','lists','locator','locator-tool','locktool',
        'lolrrit-wm','lp-tools','lyan','lziad','machtsinn',
        'machtsinn-dev','magnus-toolserver','magnustools','magog','maintgraph',
        'majavah-bot','makeref','map','map-of-monuments','map-search',
        'mapillary-commons','maplayers-demo','mapycz','massmailer','massviews',
        'massviews-test','mathbot','mathqa','matsubot','matthewrbowker',
        'matthewrbowker-dev','matvaretabellen','mbh','mbrt1','mdaniels-acc-dev',
        'mdaniels-refill-ng','mdaniels-refill-ng-api','media-reports','mediaviews','mediawiki-feeds',
        'mediawiki-mirror','meetbot','meetingtimes','merge2pdf','meta',
        'meta2','metamine','metaviews','metricslibrary','mhwikibot',
        'mirador','missing-from-wikipedia','missingpages','missingtopics','mitmachen',
        'mix-n-match','mmt','moedata','montage','montage-dev',
        'monumental','monumental-glam','morfeusz','mormegil','mortar',
        'most-readable-pages','most-wanted','mostlinkedmissing','mp','mrmetadata',
        'msbits','mstools','mu','multichill','multicompare',
        'multidesc','musikanimal','mw2sparql','mwpackages','mwph-api',
        'mwstew','mwversion','my-first-django-oauth-app','my-first-flask-oauth-tool','my-first-flask-tool',
        'my-threads','mysql-php-session-test','mywikitool','mzmcbride','nagf',
        'namakemono','nearby-places-viewer','neechal','neechalbot','new-q5',
        'newbie-uploads','newusers','ninthcircuit','niosh','nli-wiki',
        'noclaims','nodejs-mw-oauth-tool','nodetree','nominatim','nordic-museum-depicts',
        'not-in-the-other-language','npp-lv','nppdash','nsfw','oabot',
        'oabot-wd-game','oauth-hello-world','oauthtest','ocrtoy','octodata',
        'oddol','olympics','onetools','oojs-ui','ooui-debug',
        'opendatasets','openrefine-wikidata','openstack-browser','openstack-browser-dev','orator-matcher',
        'order-user-by-reg','ordia','ores','ores-demos','ores-support-checklist',
        'orphantalk','os-deprecation','osm','osm-add-tags','osm-gadget-leaflet',
        'osm4wiki','osmlint','otrsreports','outreachy-user-contribution-tool','outreachy-user-ranking-tool',
        'outreachy-wikicv','pagecount','pagecounts','pagepile','pagepile-visual-filter',
        'pageviews','pageviews-test','panoviewer','para','parliament-diagram-generator',
        'parliamentdiagram','paste','pathoschild-contrib','pathway-viewer','patrall',
        'patrolstats','paws','paws-dev','paws-support','pb',
        'pbbot','peachy-docs','periodibot','permission-denied-test','persondata',
        'petscan-md','pg2ws','phab-ban','phabricator-bug-status','phabricator-reporter',
        'phabsearchemail','phabulous','phetools','phpcs','phpinfo',
        'piagetbot','pirsquared','plagiabot','plaigsossbot','plantel2wiki',
        'plnode','plstools','pltools','poiimport','popularpages',
        'portal','portal-stats','position-holder-history','potd-viewer','povoconta',
        'powow','precise-tools','primary-sources-v2','primerpedia','prism',
        'project-fa','projector','projektneuheiten-feed','prompter','proneval-gsoc17',
        'prop-explorer','proxies','ptable','ptbot','ptools',
        'ptwikis','pub','push-notifications-helper','pyshexy','pywikibot',
        'pywikibot-testwiki','pywikipedia','qrcode-generator','quarrybot-enwiki','quentinv57-tools',
        'query','query2map','quick-intersection','quickcategories','quickpreset-migrate',
        'quickstatements','railways','random-featured','randomincategory','rang',
        'rangeblockfinder','rank','raun','reader','readmore',
        'reasomics','reasonator','recitation-bot','recoin','redirectviews',
        'redirtest','redpanda','referee','refill','refill-api',
        'refswikipedia','reftoolbar','relgen','remarkup2wikitext','render',
        'render-tests','replacer','replag','request','revertstat',
        'review-stats','reviewers','reviewtools','rezabot','rfastats',
        'ri-diff-fixture-updater','ricordisamoa','rightstool','rm-stats','rmstats',
        'robin','rotbot','roundtripping','ru_monuments','ruarbcom',
        'ruarbcom-js','ruprecht','russbot','rxy','ryu',
        'sal','sau226test','sbot','scholia','scholia-analytics',
        'scholia-dev','scribe','sdbot','sdzerobot','searchsbl',
        'section-links','secwatch','seealsology','serviceawards','sge-jobs',
        'sge-status','shex-simple','shexia','shexstatements','shextranslator',
        'shields','shortnames','shorturls','shrinitools','shuaib',
        'shuaib-bot','sibu','sibutest','sighting','sigma',
        'sign-language-browser','signatures','similarity','simplewd','sistercities',
        'siteviews','slow-parse','slumpartikel','smv-description-translations','snapshots',
        'socksfinder','sonarqubebot','sourcemd','soweego','sowhy',
        'spacemedia','spdx','speed-patrolling','speedpatrolling','spellcheck',
        'sphinxcapt-leaderboard','spi-tools','spi-tools-dev','spiarticleanalyzer','sqid',
        'sql-optimizer','squirrelnestbot','srwiki','stashbot','static',
        'statistics','statistics-api','status','steinsplitter','stemmeberettigelse',
        'stereoskopie','stewardbots','stimmberechtigung','stockholm-mania','strephit',
        'stylize','suggestbot','summary-generator','supercount','superyetkin',
        'superzerocool','svg-map-maker','svgcheck','svgedit','svgtranslate',
        'svgtranslate-test','svgworkaroundbot','swviewer','sybot51','symabot',
        'tabernacle','tabletop','tabulist','taxoboxalyzer','tedbot',
        'teg','templatecheck','templatecount','templatedata-filler','templatehoard',
        'templatetiger','templatetransclusioncheck','templator','tessdata','tesseract-ocr-service',
        'test-webservice-generic','testwikis','text2hash','textcatdemo','tfaprotbot',
        'thankyou','thebook','thibaut120094','thibtools','threed2commons',
        'tilde','time-convertor','timerelengteam','timescale','title-search',
        'tool-db-usage','toolhub','tools-gallery','tools-info','toolschecker',
        'toolschecker-k8s-ws','toolscript','toolserver','toolserver-home-archive','tooltranslate',
        'toolviews','topicmatcher','topviews','topviews-test','totoazero',
        'tour','tptools','traffic-grapher','train-blockers','translate',
        'translate-bot','translatemplate','translation-server','trusty-deprecation','trusty-tools',
        'tsbot','tsreports','tts-comparison','tulsibot','twitter-to-commons',
        'twl17','typos','typoscan','ukbot','universalviewer',
        'unpkg','upload-stats-bot','uploadhelper-ir','urbanecm-test-1','urbanecmbot',
        'urdubot','url-converter','url2commons','usage','user-contributions-feed',
        'user-id','usernamesearch','userrank','userviews','usrd-tools',
        'usualsuspects','valhallasw-test-redis','validator','vcat','vector-dark',
        'veertje-tools','vendor','versions','video-cat-bot','video-cut-tool',
        'video-cut-tool-back-end','video2commons','video2commons-socketio','video2commons-test','videoconvert',
        'videotutorials','visualcategories','vvoters','w-slackbot','wahldiagramm',
        'wakt','wam-article-suggestions','warped-to-iframe','watch-translations','watroles',
        'wawewewi','wb2rdf','wbwcalculator','wcam-bot','wcna-2018-registration',
        'wd-analyst','wd-depicts','wd-image-positions','wd-query-builder','wd-rank',
        'wd-ref-island','wd-shex-infer','wdbeoupdate','wdgraph','wdmap',
        'wdmm','wdprop','wdq-checker','wdq2sparql','wdqs-wmil-tutorial',
        'wdreconcile','wdumps','wdvaliditycheck','wdvd','weapon-of-mass-description',
        'weapon-of-mass-description-test','webarchivebot','weeklypedia','wembedder','whichsub',
        'whodunnit','whois','whois-referral','whois-referral-dev','widar',
        'wiki-as-git','wiki-loves-earth-2019','wiki-talk','wiki-tennis','wiki-todo',
        'wiki-topic','wiki13','wiki2email','wiki2prop','wiki3d',
        'wikibase-preview','wikibase-termbox-storybook','wikibugs','wikicite-dashboard','wikicontrib',
        'wikicup','wikidata-analysis','wikidata-externalid-url','wikidata-game','wikidata-janitor',
        'wikidata-primary-sources','wikidata-reconcile','wikidata-redirects-conflicts-reports','wikidata-slicer','wikidata-terminator',
        'wikidata-timeline','wikidata-todo','wikidata-trends','wikidiff2-dev-test','wikidipendenza',
        'wikiedudashboard','wikiedudashboard-test','wikifactmine-api','wikifile-transfer','wikigrade',
        'wikihistory','wikiinfo','wikilaeum','wikilinkbot','wikilist',
        'wikiloop','wikiloves','wikilovesdownloads','wikimap','wikimedia-france',
        'wikinity','wikinity-test','wikintu','wikioverdata','wikipathways2wiki',
        'wikipedia-android-builds','wikipedia-contributor-locations','wikipedia-fetch-content','wikipedia-library','wikipedia-readability',
        'wikiportretdev','wikiprovenance','wikiradio','wikishield','wikishootme',
        'wikisoba','wikisource-bot','wikisource-penguin-classics','wikistats','wikistream',
        'wikitabs','wikitei','wikitext-deprecation','wikitools','wikitree',
        'wikitweets','wikivoyage','wikiwhatsappbot','wiktioutils','wikyrillomat',
        'winter','wiper','wits','wiwosm','wle',
        'wlm-maps','wlm-stats','wlm-us','wlmtrafo','wlmuk',
        'wmcharts','wmcounter','wmcz','wmde-access','wmde-reference-previews',
        'wmf-sitematrix','wmf-task-samtar','wmopbot','wmpt','wmukevents',
        'women-in-red','wordcount','worklist-tool','wp-world','wpcleaner',
        'wprequests','wptestblog','wptestblog2','wpv','wrcp',
        'ws-cat-browser','ws-google-ocr','ws-search','ws2wd','wscontest',
        'wsexport','wsexport-test','wudele','www-portal-builder','xfd-stats',
        'xslack','xtools','xtools-articleinfo','xtools-autoedits','xtools-dev',
        'xtools-ec','xtools-pages','xyzbot','yabbr','yadfa',
        'yadkard','yellowbot','yemen','yifeibot','youtube-channel',
        'ytcleaner','zhaofeng-test','zhdeletionpedia','zhnotofu','zhwiki-qualifications-check',
        'zhwiki-username-check','zonestamp','zoomable-images','zoomproof','zoomviewer',
        'zppixbot','zppixbot-test','zumraband',
    }

    if allowed[toolname] then
        return true
    end

    return false
end

--- Generate the redirect URL by checking first for nginx vars for safety
-- @param toolname Name of the tool
-- @param path Path fragment of URL
function compute_redirect_url(toolname, path)
    -- toolname and path were checked in the previous function

    if not ngx.var.canonical_scheme then
        ngx.log(ngx.STDERR, 'ERROR: no $canonical_scheme var defined in nginx conf. This is a Toolforge outage!')
        ngx.log(ngx.STDERR, 'ERROR: the LUA code expects the $canonical_scheme var to be set to "https://"')
        ngx.exit(ngx.HTTP_INTERNAL_SERVER_ERROR)
    end

    if not ngx.var.canonical_domain then
        ngx.log(ngx.STDERR, 'ERROR: no $canonical_domain var defined in nginx conf. This is a Toolforge outage!')
        ngx.log(ngx.STDERR, 'ERROR: the LUA code expects the $canonical_domain var to be set to "toolforge.org"')
        ngx.exit(ngx.HTTP_INTERNAL_SERVER_ERROR)
    end

    local is_args = ''
    if ngx.var.is_args then
        is_args = ngx.var.is_args
    end
    local args = ''
    if ngx.var.args then
        args = ngx.var.args
    end

    return ngx.var.canonical_scheme .. toolname .. '.' .. ngx.var.canonical_domain .. path .. is_args .. args
end

--- Look up a canonical redirect target for a given tool
-- @param toolname Name of the tool
-- @param path Path fragment of the URL
function try_redirect_and_exit_if_ok(toolname, path)
    if not toolname or not path then
        return
    end

    if not toolname_allowed(toolname) then
        return
    end

    -- We are redirecting the following:
    --- from  tools.wmflabs.org/$tool/index.php?param=foo
    --- to    $tool.toolforge.org/index.php?param=foo
    -- redirect happens right here; nothing else is evaluated in the nginx conf
    return ngx.redirect(compute_redirect_url(toolname,path), 308)
end

local captures = ngx.re.match(ngx.var.uri, "^/([^/]*)(/.*)?$")
local toolname = captures[1]
local path = captures[2] or "/"
try_redirect_and_exit_if_ok(toolname, path)

-- general error case:
return ngx.redirect('https://www.toolforge.org/')
