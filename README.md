CCNシミュレータ
======================
ルータがキャッシュを持つことができるネットワークを想定し、
効率の良いルーティング方式を研究するためのシミュレータです。
 
使い方
------
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
            contentNum:         1000,                    # コンテンツ数                   
            routerCacheSize:    2,                     # ルータキャッシュサイズ           
            zipf:               0.7,                   # zipf係数                         
            linkWidth:          1.0,                   # 帯域幅 1Gbps = 125 kBps          
            contentPacket:      10.0,                  # パケット数 100k                  
            queryPacket:        1.0,                   # パケット数 1k                    
            queryLimitHopCount: 100,                   # クエリ最大ホップ数               
            logFile:            "statics.log",         # ログファイル出力ファイル名       
            POP_HistoryNum:     2000,                  # BCPOPクエリ履歴数                
            bcViewerLog:        0,                     # BCViewer用ログ出力フラグ         
            bandWidth:          false,                # 帯域再現有無フラグ                
        }

パラメータの解説
----------------
+    `time`        イベント実行時間（変更不可）
+    'message'     イベント実行内容（変更不可）
+    'routerType'  ルータタイプを指定
+    'message'  イベントの内容（変更不可）
+    'message'  イベントの内容（変更不可）

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
        contentNum:         1000,                    # コンテンツ数                   
        routerCacheSize:    2,                     # ルータキャッシュサイズ           
        zipf:               0.7,                   # zipf係数                         
        linkWidth:          1.0,                   # 帯域幅 1Gbps = 125 kBps          
        contentPacket:      10.0,                  # パケット数 100k                  
        queryPacket:        1.0,                   # パケット数 1k                    
        queryLimitHopCount: 100,                   # クエリ最大ホップ数               
        logFile:            "statics.log",         # ログファイル出力ファイル名       
        POP_HistoryNum:     2000,                  # BCPOPクエリ履歴数                
        bcViewerLog:        0,                     # BCViewer用ログ出力フラグ         
        bandWidth:          false,                # 帯域再現有無フラグ            

+   `param1` :
    _パラメータ1_ の説明
 
+   `param2` :
    _パラメータ2_ の説明
 
関連情報
--------
### リンク、ネストしたリスト
1. [リンク1](http://example.com/ "リンクのタイトル")
    * ![画像1](http://github.com/unicorn.png "画像のタイトル")
2. [リンク2][link]
    - [![画像2][image]](https://github.com/)
 
  [link]: http://example.com/ "インデックス型のリンク"
  [image]: http://github.com/github.png "インデックス型の画像"
 
### 引用、ネストした引用
> これは引用です。
>
> > スペースを挟んで `>` を重ねると、引用の中で引用ができますが、
> > GitHubの場合、1行前に空の引用が無いと、正しくマークアップされません。
 
ライセンス
----------
Copyright &copy; 2011 xxxxxx
Licensed under the [Apache License, Version 2.0][Apache]
Distributed under the [MIT License][mit].
Dual licensed under the [MIT license][MIT] and [GPL license][GPL].
 
[Apache]: http://www.apache.org/licenses/LICENSE-2.0
[MIT]: http://www.opensource.org/licenses/mit-license.php
[GPL]: http://www.gnu.org/licenses/gpl.html