CCNシミュレータ
======================
ルータがキャッシュを持つことができるネットワークを想定し、
効率の良いルーティング方式を研究するためのシミュレータです。
 
使い方
------
開発環境  

    ruby 2.1

起動コマンド

    ruby Simulator.rb setting_file

setting_fileの解説
------

    {
        time:               0,                     # 変更不可  
        message:            :setting,              # 変更不可  
        briteFile:          "N500L2000WAX1.brite", # BRITEファイルを指定  
        routerType:         :IP,                   # BC,TERC,POP,BCPOP  
        simulationTime:     1000,                  # クエリ生成時間  
        simulationStopTime: 110000,                # シミュレーション強制終了時間  
        queryGenerateTime:  1.0,                   # 平均クエリ生成時間間隔  
        seed:               1,                     # 乱数シード  
        routerNum:          nil,                   # 設定ファイルから自動設定  
        linkNum:            nil,                   # 設定ファイルから自動設定  
        userNum:            1,                     # ルータに接続するユーザ数  
        serverNum:          500,                   # ルータに接続するサーバ数   
        contentNum:         1000,                  # コンテンツ数  
        routerCacheSize:    2,                     # ルータキャッシュサイズ  
        zipf:               0.7,                   # zipf係数  
        linkWidth:          1.0,                   # 帯域幅 1Gbps = 125 kBps  
        contentPacket:      10.0,                  # パケット数 100k  
        queryPacket:        1.0,                   # パケット数 1k  
        queryLimitHopCount: 100,                   # クエリ最大ホップ数  
        logFile:            "statics.log",         # ログファイル出力ファイル名  
        POP_HistoryNum:     2000,                  # BCPOPクエリ履歴数  
        bcViewerLog:        0,                     # BCViewer用ログ出力フラグ  
        bandWidth:          false,                 # 帯域再現有無フラグ  
    }

パラメータの解説
----------------
+    `time`        
     イベント実行時間（変更不可）
+    `message`     
      イベント実行内容（変更不可）
+    `briteFile`  
      [Brite][Brite]で出力されたトポロジファイル名を指定する
+    `routerType`  
     指定されたルータタイプに基づいた処理が行われる。
     プログラム的にはRouter_#{routerType}モジュールが実行される
+    `simulationTime`  
     指定された時間までクエリの生成を行う
+    `simulationStopTime`  
     未実行イベントが残っていても指定された時間にシミュレーションが強制終了する
     例えばクエリがループ状に転送されている場合でも、結果を取得するために指定する
+    `queryGenerateTime`  
     指定された時間間隔でクエリの生成が行われる
+    `seed`  
     指定されたシード値を元にクエリの生成などが行われる
+    `routerNum`  
     指定されたBriteファイルから自動設定         
+    `linkNum`  
     指定されたBriteファイルから自動設定         
+    `userNum`
     ルータに接続されたユーザ数を指定する  
     全ユーザ数では無いことに注意
+    `serverNum`
     全サーバ数を指定する  
     サーバは偏りを避けてランダムに配置される  
+    `contentNum`  
     総コンテンツ数を指定する  
     コンテンツ数が均一になるようにサーバへ配置される  
+    `routerCacheSize`  
     ルータが持つことができるコンテンツキャッシュ数を指定する  
+    `zipf`  
     コンテンツ人気度を決定するzipf則の係数を指定する  
+    `linkWidth`  
     帯域幅を指定する（単位は パケット/s)  
+    `contentPacket`:  
     コンテンツのパケット数を指定する                 
+    `queryPacket`  
     クエリのパケット数を指定する
+    `queryLimitHopCount`  
     クエリ最大ホップ数を指定する
     指定されたホップ数以上になるとエラーとしてカウントされる     
+    `logFile`  
     すべてのイベントを記述したログの出力ファイル名を指定する
+    `POP_HistoryNum`    
     POP方式で使用するクエリの履歴数を指定する                
+    `bcViewerLog`                       
     BCViewer用ログ出力フラグ         
+    `bandWidth`  
     帯域を再現するかどうかのフラグ 

出力ファイルについて
--------
+    `staticsAry.csv`  
     主な統計情報を出力
+    `routerAry.csv`  
     ルータごとの統計情報を出力
+    `serverAry.csv`  
     サーバごとの統計情報を出力
+    `linkAry.csv`  
     リンクごとの統計情報を出力
+    `contentAry.csv`  
     コンテンツごとの統計情報を出力
+    `userAry.csv`  
     ユーザごとの統計情報を出力

ライセンス
----------
Copyright &copy; 2015 Kotaro Fujii
Distributed under the [MIT License][mit].

[MIT]: http://www.opensource.org/licenses/mit-license.php
[Brite]: http://www.cs.bu.edu/brite/
