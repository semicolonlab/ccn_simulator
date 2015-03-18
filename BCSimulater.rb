# coding: utf-8
$gSettingAry={ # コマンドライン引数なしのとき使用するパラメータ
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
  contentNum:         10,                    # コンテンツ数 
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

class ROUTER
  Dir::entries("./").each{|f| 
    if f.index("Router_") && f.index(".rb") # Router_[^.]+.rb
      require "./#{f.gsub(".rb","")}"       # モジュールを読み込む
      eval "extend #{f.gsub(".rb","")}"     # クラスメソッドとして定義
    end
  }
  
  @@mRouterAry = {} # Router情報を記憶する配列 Mainクラス内で設定

  def self.GetRouterAry() @@mRouterAry end # クラス変数のGetter
  
  def self.SetRouterAry(routerAry) @@mRouterAry = routerAry end # クラス変数のSetter
  
  def self.Init()
    @@mRouterAry.each{ |id,router|
      routerType = router[ :routerType ]
      send( "Router_#{ routerType }_Init" )
    }
  end
  
  def self.ReceiveQuery( inEvent )
    routerType = @@mRouterAry[ inEvent[ :nodeId ] ][ :routerType ]
    send( "Router_#{ routerType }_ReceiveQuery", inEvent )
  end

  def self.ReceiveContent( inEvent )
    routerType = @@mRouterAry[ inEvent[ :nodeId ] ][ :routerType ]
    send( "Router_#{ routerType }_ReceiveContent", inEvent )
  end
  
  def self.CreateCache( inEvent )
    routerType = @@mRouterAry[ inEvent[ :nodeId ] ][ :routerType ]
    send( "Router_#{ routerType }_CreateCache", inEvent )
  end
  
  def self.DeleteCache( inEvent )
    routerType = @@mRouterAry[ inEvent[ :nodeId ] ][ :routerType ]
    send( "Router_#{ routerType }_DeleteCache", inEvent )
  end
  
  def self.CacheHit( inEvent )
    routerType = @@mRouterAry[ inEvent[ :nodeId ] ][ :routerType ]
    send( "Router_#{ routerType }_CacheHit", inEvent )
  end
  
  def self.CreateBc( inEvent )
    routerType = @@mRouterAry[ inEvent[ :nodeId ] ][ :routerType ]
    send( "Router_#{ routerType }_CreateBc", inEvent )
  end
  
  def self.DeleteBc( inEvent )
    routerType = @@mRouterAry[ inEvent[ :nodeId ] ][ :routerType ]  
    send( "Router_#{ routerType }_DeleteBc", inEvent )
  end
    
end

class USER
  @@mUserAry = {}
  @@mQueryId = -1
  
  def self.GetUserAry() @@mUserAry end

  def self.GetRandomUserNodeId() 
    @@mUserAry.keys[ $gRandom.rand( @@mUserAry.length ) ] 
  end

  def self.Init()
    ROUTER.GetRouterAry.keys.each{|i| 
      $gSettingAry[:userNum].times{|j|
        @@mUserAry[ "#{i}.U#{j}".to_sym]={} 
      } 
    }
  end
  
  def self.GeneratePacket( event )
    serverNodeId = CONTENT.GetContentAry[event[:contentId]][:serverNodeId]
    packet = {
      time:               1.0 * event[:time],
      message:            :linkRegisterQuery,
      nodeId:             event[:userNodeId],
      nextNodeId:         event[:userNodeId].to_s.split(".")[0].to_sym,
      queryPacketSize:    $gSettingAry[ :queryPacket ],
      queryHopCount:      0,
      contentHopCount:    0,
      contentPacketSize:  $gSettingAry[ :contentPacket ],
      contentId:          event[:contentId],
      pastNodeId:         event[:userNodeId],
      userNodeId:         event[:userNodeId],
      userRouterId:       event[:userNodeId].to_s.split(".")[0].to_sym,
      serverNodeId:       serverNodeId,
      serverRouterId:     serverNodeId.to_s.split(".")[0].to_sym,
      queryId:            @@mQueryId += 1,
      viaNodeIdAry:       [],
      querySendTime:      event[:time],
      contentSendTime:    nil,
      contentReceiveTime: nil,
      bcFlag:             false,
    }
  end

  def self.GenerateQuery( event )
    query = GeneratePacket( event )
    EVENT.Register( query )
    userGenerateQuery = {
      :time              => event[:time] + $gSettingAry[ :queryGenerateTime ],
      :message           => :userGenerateQuery,
      :contentId         => CONTENT.GetRandomContentId,
      :userNodeId        => USER.GetRandomUserNodeId,
    }
    EVENT.Register( userGenerateQuery ) if event[ :time ] <= $gSettingAry[ :simulationTime ]
  end

  def self.ReceiveContent( inEvent )
    Error( "viaNodeIdAry", __LINE__ )if inEvent[:viaNodeIdAry].length > 0
    Error( "UserReceiveContent Node Id", __LINE__ )if inEvent[:nodeId] == nil    
  end

  def self.ReceiveQuery( inEvent )
    Error("USERReceiveQuery", __LINE__)
  end

end

class SERVER
  @@mServerAry = {}
  
  def self.GetServerAry() @@mServerAry end

  def self.Init( inRouterAry )
    cResetServerAry = lambda{| ioServerAry, inServerNum |
      inServerNum.times{| i |
        ioServerAry[ "S#{i}".to_sym ] = {
          :routerId => nil,
        }
      }
    }
    cSetServerRouterId = lambda{| ioServerAry, inRouterIdAry |
      routerIdCloneAry = []
      ioServerAry.length.times{|i|
        routerIdCloneAry = inRouterIdAry.clone if routerIdCloneAry == []
        routerIdCloneAryLen = routerIdCloneAry.length
        routerId = routerIdCloneAry.delete_at( $gRandom.rand( routerIdCloneAry.length ).floor )
        ioServerAry[ "S#{i}".to_sym ][ :routerId ] = routerId
      }
    }
    cResetServerAry.call( @@mServerAry, $gSettingAry[ :serverNum ] )
    cSetServerRouterId.call( @@mServerAry, inRouterAry.keys )    
  end
  def self.ReceiveQuery( inEvent )
    inEvent[ :contentSendTime ] = inEvent[ :time ]
    inEvent[ :message ] = :linkSendContent
    inEvent[ :nextNodeId ] = inEvent[ :serverRouterId ]
    LINK.RegisterContent( inEvent )
  end
end

class CONTENT
  @@mContentAry={}
  @@total=0
  @@mTime = 0
  @@mContentIdAry = []
  def self.GetContentAry() @@mContentAry end
  def self.SetPopularity()
    puts "Start SetPopularity"
    sum = ( 1..$gSettingAry[:contentNum] ).to_a.inject(0){|x,n| x += 1 / n**$gSettingAry[:zipf] }
    populality = ( 1..$gSettingAry[:contentNum] ).to_a.map{ | k | ( 1 / k**$gSettingAry[:zipf] ) / sum }
    populality.map!{|i| @@total += i }
    serverIdAry = SERVER.GetServerAry.keys
    populality.each_with_index.map{|x,i| 
      serverId = serverIdAry[ $gRandom.rand( $gSettingAry[:serverNum] ).floor ]
      serverRouterId = SERVER.GetServerAry[ serverId ][:routerId]
      @@mContentAry["C#{i}".to_sym] = {
        :popularity    => x,
        :serverId      => serverId,
        :serverRouterId=> serverRouterId,
        :serverNodeId  => "#{serverRouterId}.#{serverId}".to_sym ,
        :contentId     => "C#{i}".to_sym }
    }
    @@mContentIdAry = @@mContentAry.keys
  end

  def self.FindContentIdFast( x )
    low = 0
    high = @@mContentIdAry.length - 1
    while low <= high
      mid = ( low + high ) / 2
      case x <=> @@mContentAry[ @@mContentIdAry[ mid ] ][:popularity]
        when 0 then return @@mContentIdAry[ mid ]
        when -1 then high = mid - 1
        when 1 then low = mid + 1
      end
    end
    @@mContentIdAry[ low ]
  end

  def self.GetRandomContentId
    total = 0
    rand = $gRandom.rand( @@total )
    contentId = self.FindContentIdFast( rand )
  end
end

class LINK
  @@mLinkAry={}
  def self.GetLinkAry
    @@mLinkAry
  end
  
  def self.Init( inRouterAry, inUserAry ) # LINK.Init()
    puts "Start LINK.Init" # 【リンク設定開始】
    inRouterAry.keys.each{|i| @@mLinkAry[i] = inRouterAry[i][:edgeAry].inject({}){|x,j| x[j]=0; x} } # 【ルータ・ルータ間のリンク】を設定
    CONTENT.GetContentAry.each{|k,i| # 【サーバ・ルータ間のリンク】を設定
      @@mLinkAry[i[:serverNodeId]]={} # 【サーバからのリンク】を登録
      routerId = (i[:serverNodeId].to_s.split(".")[0]).to_sym
      serverId = i[:serverNodeId]
      @@mLinkAry[routerId][serverId]=0 # 【ルータ・サーバ間のリンク】を初期化
      @@mLinkAry[serverId][routerId]=0 
    }
    USER.GetUserAry.keys.map{|userNodeId| # 【ユーザ・ルータ間のリンク】を設定
      routerId = (userNodeId.to_s.split(".")[0]).to_sym
      @@mLinkAry[userNodeId]={} # 【ユーザからのリンク】を登録
      @@mLinkAry[routerId][userNodeId] = 0 # 【ルータ・ユーザ間のリンク】を初期化
      @@mLinkAry[userNodeId][routerId] = 0 } # 【ユーザ・ルータ間のリンク】を初期化
   end

  def self.RegisterQuery( inEvent ) # LINK.RegisterQuery()
    cCalcSendTime = lambda{
      cCalcSendTime_BandWidth = lambda{
        time = [ @@mLinkAry[inEvent[:nodeId]][inEvent[:nextNodeId]] ,inEvent[:time]].max
        @@mLinkAry[inEvent[:nodeId]][inEvent[:nextNodeId]] = time + inEvent[:queryPacketSize] / $gSettingAry[ :linkWidth ] 
        return time
      }
      if $gSettingAry[ :bandWidth ]
        return cCalcSendTime_BandWidth.call
      else
        return inEvent[:time]
      end
    }

    cOverQueryLimit = lambda{
      return false if inEvent[:queryHopCount] < $gSettingAry[ :queryLimitHopCount ]
      puts inEvent[:contentId]
      return true
    }
    inEvent[:message] = :linkSendQuery
    return if cOverQueryLimit.call
    puts inEvent if inEvent[ :nextNodeId ] == nil
    Error( "nextNodeId Error" , __LINE__ ) if inEvent[ :nextNodeId ] == nil

    return EVENT.Register( inEvent ) if inEvent[ :nodeId ] == inEvent[ :nextNodeId ]
    inEvent[:time] = cCalcSendTime.call
    EVENT.Register( inEvent )
  end
  
  def self.RegisterContent( inEvent ) # LINK.RegisterContent()
    cCalcSendTime = lambda{
      cCalcSendTime_BandWidth = lambda{
        time = [ @@mLinkAry[inEvent[:nodeId]][inEvent[:nextNodeId]] ,inEvent[:time]].max
        @@mLinkAry[inEvent[:nodeId]][inEvent[:nextNodeId]] = time + inEvent[:contentPacketSize] / $gSettingAry[ :linkWidth ] 
        return time
      }
      if $gSettingAry[ :bandWidth ]
        return cCalcSendTime_BandWidth.call
      else
        return inEvent[:time]
      end
    }

    inEvent[:message] = :linkSendContent
    return EVENT.Register( inEvent ) if inEvent[:nodeId] == inEvent[:nextNodeId]
    Error( "nextNodeId Error" , __LINE__ ) if inEvent[ :nextNodeId] == nil
    inEvent[:time] = cCalcSendTime.call
    EVENT.Register( inEvent )
  end
    
  def self.SendQuery( inEvent ) # Link.SendQuery()
    inEvent[:time] += $gSettingAry[ :queryPacket ] / $gSettingAry[ :linkWidth ]
    inEvent[:pastNodeId] = inEvent[ :nodeId ]
    inEvent[:nodeId] = inEvent[ :nextNodeId ]
    inEvent[:nextNodeId] = nil
    inEvent[:queryHopCount] += 1
    if inEvent[ :nodeId ].to_s.index( "S" ) != nil # 【サーバ】へ転送か？
      inEvent[:message] = :serverReceiveQuery
      EVENT.Register( inEvent ) # 【サーバ】へ転送
    else # 【ルータ】へ転送か？
      inEvent[:message] = :routerReceiveQuery
      EVENT.Register( inEvent ) # 【ルータ】へ転送
    end
  end
  def self.SendContent( inEvent ) # Link.SendContent()
      inEvent[:time] += $gSettingAry[ :contentPacket ]/ $gSettingAry[ :contentPacket ] / $gSettingAry[ :linkWidth ] # 次リンクまでの転送時間を加算
      inEvent[:pastNodeId] = inEvent[:nodeId] # 過去のノードを設定
      inEvent[:nodeId] = inEvent[:nextNodeId] # 【ノードID】に次ノードのIDを設定
      inEvent[:nextNodeId] = nil # 【転送先ノード】をリセット
      inEvent[:contentHopCount] += 1 # 【コンテンツホップ数】を増やす
      if inEvent[ :nodeId ].to_s.index( "U" ) != nil # 【ユーザ】へ転送か？
        inEvent[:message] = :userReceiveContent
        inEvent[:contentReceiveTime] = inEvent[ :time ] + ( inEvent[:contentPacketSize] ) / $gSettingAry[ :linkWidth ]
        EVENT.Register( inEvent ) # 【ユーザ】へ転送
        return 
        #EVENT.Log( inEvent )
        #USER.ReceiveContent( inEvent ) # 【ユーザ】へ転送
      else # 【ルータ】転送
        inEvent[:message] = :routerReceiveContent # 次イベントを【ルータコンテンツ受信処理】に設定
        EVENT.Register( inEvent ) # 【ルータ】へ転送
        return 
        # EVENT.Log( inEvent )
        # ROUTER.ReceiveContent( inEvent )
      end
  end
end

class EVENT # 全てのイベント管理するクラス
  @@mEventAry = []
  @@mLogStr = ""
  @@mLastEventTime = - 10
  @@mEventCount = -1  
  
  def self.Register(inEvent) # イベントを登録する
    binarySearch = lambda{ | time |  # 二分探索でイベント追加位置を検索
      low = 0
      high = @@mEventAry.length - 1
      return 0 if high == -1
      while low <= high
        mid = ( low + high ) / 2
        case time  <=> @@mEventAry[ mid ][:time]
          when 0 then return mid
          when 1 then high = mid - 1
          when -1 then low = mid + 1
        end
      end
      low
    }
    pos = binarySearch.call( inEvent[:time] ) || @@mEventAry.length
    @@mEventAry[ pos, 0 ] = inEvent
  end

  def self.SaveLog() # EVENT.SaveLog()
    open( $gSettingAry[:logFile], "w" ){|f| f.write( $gSettingAry.inspect + ",\n" +@@mLogStr ) }
  end  

  def self.Run( event )
      @@mEventCount += 1
      STATICS.ReadLogAry( event )
      Error("EventTime #{event}",__LINE__) if @@mLastEventTime > event[ :time ]

      case event[:message]
        when :routerReceiveQuery         then ROUTER.ReceiveQuery( event )
        when :routerReceiveContent       then ROUTER.ReceiveContent( event )
        when :routerCreateBc             then ROUTER.CreateBc( event )
        when :routerDeleteBc             then ROUTER.DeleteBc( event )
        when :routerDeleteBcAry          then ROUTER.DeleteBcAry( event )
        when :routerCacheHit             then ROUTER.CacheHit( event )
        when :routerCreateCache          then ROUTER.CreateCache( event )
        when :routerDeleteCache          then ROUTER.DeleteCache( event )
        when :userGenerateQuery          then USER.GenerateQuery( event )
        when :userReceiveContent         then USER.ReceiveContent( event )
        when :serverReceiveQuery         then SERVER.ReceiveQuery( event )
        when :linkRegisterQuery          then LINK.RegisterQuery( event )
        when :linkRegisterContent        then LINK.RegisterContent( event )
        when :linkSendQuery              then LINK.SendQuery( event )
        when :linkSendContent            then LINK.SendContent( event )
        when :staticsInit                then STATICS.init()
        when :staticsSave                then STATICS.Save()
      else
        Error( "unknow event #event[:message]" , __LINE__ )
      end
  end  

  def self.start()
    puts "Start EVENT"
    @@mEventAry[0] = { 
      time: 0, 
      message: :userGenerateQuery, 
      contentId: CONTENT.GetRandomContentId, 
      userNodeId: USER.GetRandomUserNodeId
    }
    while ( event = @@mEventAry.pop )!= nil
      @@mLastEventTime = event[:time]
      puts event[:time].to_i.to_s + " / #{$gSettingAry[:simulationStopTime]} #{@@mEventAry.length} #{@@mEventCount}" if @@mEventCount & 4095 == 0
      Run( event )
      break if event[:time] > $gSettingAry[:simulationStopTime]
    end
    puts $gSettingAry[:simulationStopTime].to_s + " / " + $gSettingAry[:simulationStopTime].to_s + " " + @@mEventCount.to_s
    puts "End Event"
  end
end

class STATICS #シミュレション結果出力クラス
  @@linkLoadAry={}
  @@userReceiveContentAry={ totalTime: 0, contentTime: 0, queryTime: 0, totalNum: 0, }
  @@contentAry = {} # コンテンツごとの統計
  @@routerAry = {}  # ルータごとの統計
  @@userAry = {}    # ユーザごとの統計
  @@serverAry ={}   # サーバごとの統計
  @@resultAry = {}

  def self.Init()
    cInitRouterAry = lambda{ # ルータごとの統計初期化
      ROUTER.GetRouterAry.each{ |nodeId,v| 
        @@routerAry[ nodeId ] = {
          "cacheHitNum" => 0,
          "routerReceiveQuery" => 0,
          "routerReceiveQueryContent" => {},
          "contentIdAry" => {},
        }
      }
    }
    cInitContentAry = lambda{ # コンテンツごとの統計初期化
      CONTENT.GetContentAry.each{| id, content |
        @@contentAry[ id ] = {
          cacheLifeTime: 0,
          cacheCount: 0,
          "routerCacheHit"    => 0,
          "userGenerateQuery" => 0,
          "serverReceiveQuery"=> 0, 
          "deleteCache"       => 0,
          "userReceiveContent"=> 0,
          contentHopCount: 0,
          queryHopCount: 0,
          "routerCacheNum"    => 0,
          "routerCacheHitHop" => 0,
        }
      }
    }
    cInitRouterAry.call
    cInitContentAry.call
  end
  
  def self.ReadLogFile()
    puts "Read " + $gSettingAry[:logFile]
    open( $gSettingAry[:logFile] ){|f|
      f.each{ |line|
        logAry = eval( line.gsub(",\n","") )      
        self.ReadLogAry( logAry )
      }
    }
  end

  # STATICS.ReadLogAry
  def self.ReadLogAry( i )
    case( i[:message] )
      when :userReceiveContent then 
        @@userReceiveContentAry[:totalTime] += i[:time] - i[:querySendTime]
        @@userReceiveContentAry[:queryTime] += i[:contentSendTime] - i[:querySendTime]
        @@userReceiveContentAry[:contentTime] += i[:time] - i[:contentSendTime]
        @@userReceiveContentAry[:totalNum] += 1
        @@contentAry[ i[:contentId] ][ :contentHopCount ] += i[:contentHopCount]
        @@contentAry[ i[:contentId] ][ "userReceiveContent" ] += 1
        @@contentAry[ i[:contentId] ][ :queryHopCount ] += i[:queryHopCount] 
        
      when :serverReceiveQuery then
        @@contentAry[ i[:contentId] ][ "serverReceiveQuery" ] += 1
        @@serverAry[ i[:nodeId] ]["serverCacheHit"] +=1 
      when :routerCacheHit     then
        @@contentAry[ i[:contentId] ][ "routerCacheHit" ] += 1
        if ROUTER.GetRouterAry[ i[ :nodeId ] ][ :hopCountAry ][ i[:serverRouterId] ] == nil # サーバに接続されるルータの場合
          hopCount = 0 + 1
        else # hopCountが設定されている場合
          hopCount = ROUTER.GetRouterAry[ i[ :nodeId ] ][ :hopCountAry ][ i[:serverRouterId] ] + 1
        end
        @@contentAry[ i[:contentId] ][ "routerCacheHitHop" ] += hopCount

        @@routerAry[ i[:nodeId] ][ "cacheHitNum" ] += 1
        if @@routerAry[ i[:nodeId] ][ "contentIdAry" ][ i[:contentId] ] == nil
          @@routerAry[ i[:nodeId] ][ "contentIdAry" ][ i[:contentId] ] = 0
        end
        @@routerAry[ i[:nodeId] ][ "contentIdAry" ][ i[:contentId] ] += 1

      when :userGenerateQuery  then
        serverNodeId = CONTENT.GetContentAry[i[:contentId]][:serverNodeId]

        @@contentAry[ i[:contentId] ][ "userGenerateQuery" ] += 1
        if @@userAry[ i[ :userNodeId ] ]  == nil
          @@userAry[ i[ :userNodeId ] ] = {
            "userGenerateQuery" => 0,            
          }
        end
        @@userAry[ i[ :userNodeId ] ][ "userGenerateQuery" ] += 1        
        if @@serverAry[ serverNodeId ]  == nil
          @@serverAry[ serverNodeId ] = {
            "userGenerateQuery" => 0,            
            "serverCacheHit"    => 0,
          }
        end
        @@serverAry[ serverNodeId ][ "userGenerateQuery" ] += 1
      when :routerDeleteCache then 
        @@contentAry[ i[:contentId] ][ "deleteCache" ] += 1
        @@contentAry[ i[:contentId] ][ :cacheLifeTime ]  += i[ :time ] - i[ :cacheTime ]
        
      when :routerReceiveQuery then
        @@routerAry[ i[:nodeId] ][ "routerReceiveQuery" ] += 1
        @@routerAry[ i[:nodeId] ][ "routerReceiveQueryContent" ][ i[ :contentId ] ] = 0 if @@routerAry[ i[:nodeId] ][ "routerReceiveQueryContent" ][ i[:contentId] ] == nil
        @@routerAry[ i[:nodeId] ][ "routerReceiveQueryContent" ][ i[ :contentId ] ] += 1
        
      when :linkSendQuery   then setQueryLinkLoadAry( i )
      when :linkSendContent then setContentLinkLoadAry( i )
    end
  end

  def self.setQueryLinkLoadAry( log )
    from = log[:nodeId]
    to = log[:nextNodeId]
    @@linkLoadAry[ "#{from}-#{to}" ] = {"packet"=>0} if @@linkLoadAry[ "#{from}-#{to}" ] == nil
    @@linkLoadAry[ "#{from}-#{to}"]["packet"] += log[:queryPacketSize]
  end

  def self.setContentLinkLoadAry( log )
    from = log[:nodeId]
    to = log[:nextNodeId]
    @@linkLoadAry["#{from}-#{to}"] = {"packet"=>0} if @@linkLoadAry["#{from}-#{to}"] == nil
    @@linkLoadAry["#{from}-#{to}"]["packet"] += log[:contentPacketSize]
  end

  def self.SaveRouterReceiveQuery( filePath )
    routerReceiveQueryStr = "R,T,"
    CONTENT.GetContentAry.each{|contentId,content| routerReceiveQueryStr << "#{contentId}," }
    ROUTER.GetRouterAry.each{|routerId,router|
      routerReceiveQueryStr << "#{routerId},#{@@routerAry[routerId]["routerReceiveQuery"]},"
      CONTENT.GetContentAry.each{ | contentId, content | 
        if @@routerAry[ routerId ]["routerReceiveQueryContent"][ contentId ] != nil
          routerReceiveQueryStr << @@routerAry[ routerId ]["routerReceiveQueryContent"][ contentId ].to_s + ","
        else
          routerReceiveQueryStr << ","
        end
      }
      routerReceiveQueryStr << "\n"
    }
    open( filePath ,"w"){ |f| f.write( routerReceiveQueryStr ) }
  end

  def self.SaveRouterCacheHitContent( filePath )
    routerCacheHitContentStr = "R,T,"
    CONTENT.GetContentAry.each{|k,v| routerCacheHitContentStr << "#{k},"}
    ROUTER.GetRouterAry.each{|routerId,router|
      routerCacheHitContentStr << "#{routerId},#{@@routerAry[routerId]["cacheHitNum"]},"
      CONTENT.GetContentAry.each{|contentId,content|
        if @@routerAry[routerId][ "contentIdAry" ][contentId] != nil
          routerCacheHitContentStr << @@routerAry[ routerId] ["contentIdAry"][contentId].to_s + "," 
        else
          routerCacheHitContentStr << ","
        end
      }
      routerCacheHitContentStr << "\n"
    }
    open( filePath , "w"){|f| f.write( routerCacheHitContentStr ) }  

    end
  def self.SaveServerAry( inFilePath )
    outStr = "serverId,userGenerateQuery,serverCacheHit\n"
    outStr << @@serverAry.inject(""){|x,(k,v)| x << "#{k},#{v["userGenerateQuery"]},#{v["serverCacheHit"]}\n" }
    open( inFilePath, "w" ){|f| f.write( outStr )}
  end

  def self.SaveLinkLoadAry( inFilePath )
    outStr = @@linkLoadAry.sort{|(k1,v1),(k2,v2)| v2["packet"]<=>v1["packet"]}.inject(""){|x,(k,v)| x << "#{k},#{v["packet"]}\n" }
    open( inFilePath, "w" ){|f| f.write( outStr )}
  end    
  
  def self.SaveContentAry( inFilePath )
    ROUTER.GetRouterAry.each{ | routerId, router |
      router[ :cacheAry ].map{ |v| v[ :contentId ] }.each{ |cache| 
        @@contentAry[ cache ]["routerCacheNum"] += 1
      }
    }
    ROUTER.GetRouterAry.each{|k,v|
      if ( cacheAry =  v[:cacheAry] ) != nil
        cacheAry.each{|cache|
          cache[ :time ] = $gSettingAry[ :simulationTime ]
          cache[ :message ] = :routerDeleteCache
          STATICS.ReadLogAry( cache )
      }
      end
    }
    outStr = "ContentId,NodeId,RouterCacheHitNum,UserGenerateQuery,CacheHitRatio,RouterCacheNum,CacheLifeTime,DeleteCache,ContentHopCount\n"
    contentSortAry = @@contentAry.sort{|a,b| "#{a[0]}".gsub("C","").to_i<=>"#{b[0]}".gsub("C","").to_i }
    contentSortAry.each{ |contentId,v| 
      nodeId = CONTENT.GetContentAry[ contentId ][:serverNodeId]
      routerCacheHitNum =  v["userGenerateQuery"] - v["serverReceiveQuery"]
      cacheHitRatio = v["userGenerateQuery"] > 0 ? 1.0 * ( v["userGenerateQuery"] - v["serverReceiveQuery"] ) / v["userGenerateQuery"]  : 0 
      contentHopCount = v[:contentHopCount] * 1.0 / v["userGenerateQuery"]
      outStr << "#{contentId},#{nodeId},#{routerCacheHitNum},#{v["userGenerateQuery"]},#{cacheHitRatio},#{v["routerCacheNum"]},#{v[:cacheLifeTime]},#{v["deleteCache"]},#{contentHopCount}\n"
    }
    open( inFilePath ,"w"){|f| f.write( outStr ) }
  end
  
  def self.SaveRouterAry( inFilePath )
    outStr = "#routerId,cacheHitNum,routerReceiveQuery"
    @@routerAry.sort{|(k1,v1),(k2,v2)|v1["cacheHitNum"]<=>v2["cacheHitNum"]}.each{|k,v| 
      outStr << "#{k},#{v["cacheHitNum"]},#{v["routerReceiveQuery"]}\n" 
    }
    open( inFilePath ,"w"){|f| f.write( outStr ) }
  end

  def self.SaveUserAry( inFilePath )
    outStr = ""  
    @@userAry.each{|k,v| outStr << "#{k},#{v["userGenerateQuery"]}\n" if k != nil }
    open( inFilePath,"w"){|f| f.write( outStr ) }  
  end
  def self.CalcResultAry
    contentSortAry = @@contentAry.sort{|a,b| "#{a[0]}".gsub("C","").to_i<=>"#{b[0]}".gsub("C","").to_i }
    @@resultAry["userGenerateQuery"]      = @@contentAry.inject( 0 ){|x,(k,v)| x += v["userGenerateQuery"] }
    @@resultAry["serverReceiveQuery"]     = @@contentAry.inject( 0 ){|x,(k,v)| x += v["serverReceiveQuery"] }
    @@resultAry["routerCacheHit"]         = @@contentAry.inject( 0 ){|x,(k,v)| x += v["routerCacheHit"] }
    @@resultAry["deleteCache"]            = @@contentAry.inject( 0 ){|x,(k,v)| x += v["deleteCache"] }
    @@resultAry["userReceiveContent"]     = @@contentAry.inject( 0 ){|x,(k,v)| x += v["userReceiveContent"] }
    @@resultAry["maxCacheHit"]            = contentSortAry[ 0  ... $gSettingAry[:routerNum]*$gSettingAry[:routerCacheSize] ].inject(0.0){|x,(k,v)| x +=v["userGenerateQuery"]} / @@resultAry["userReceiveContent"]
    @@resultAry["cacheHitRate"]           = ( @@resultAry["routerCacheHit"] ) * 1.0 / @@resultAry["userGenerateQuery"]
    @@resultAry["loss"]                   = @@resultAry["userGenerateQuery"] - @@resultAry["userReceiveContent"]
    @@resultAry["averageQueryHopCount"]   = @@contentAry.inject( 0 ){|x,(k,v)| x += v[:queryHopCount] }   * 1.0 / @@resultAry["userReceiveContent"]
    @@resultAry["averageContentHopCount"] = @@contentAry.inject( 0 ){|x,(k,v)| x += v[:contentHopCount] } * 1.0 / @@resultAry["userReceiveContent"]
    @@resultAry["totalTime"]              = @@userReceiveContentAry[:totalTime] / @@resultAry["userReceiveContent"] 
    @@resultAry["queryTime"]              = @@userReceiveContentAry[:queryTime] / @@resultAry["userReceiveContent"]
    @@resultAry["contentTime"]            = @@userReceiveContentAry[:contentTime] / @@resultAry["userReceiveContent"]  
  end
  def self.SaveResultAry( inFilePath )
    settingStr = $gSettingAry.inspect.gsub("{","").gsub("}",",").gsub(",",",\n").gsub(" ","").gsub("nil","0")
    print( outStr  = @@resultAry.inspect.gsub("{","").gsub("}",",").gsub(",",",\n") )
    open( inFilePath, "w" ){|f| f.write( "{\n" + settingStr + "\n" + outStr.gsub("NaN","0") + "\n" + "}" ) }    
  end
  def self.SaveLog()
    cMakeFolder = lambda{
      folderName = "#{$gSettingAry[:briteFile].to_s.split(".")[0]}S#{$gSettingAry[:serverNum]}C#{$gSettingAry[:contentNum]}Q#{$gSettingAry[:simulationTime]}s#{$gSettingAry[:seed]}_#{$gSettingAry[:routerType]}"
      return folderName if File.exists?( folderName ) == true
      Dir::mkdir( folderName )
      return folderName
    }
    cGetFilePath = lambda{|inFileTag|
      folderName = cMakeFolder.call
      return "#{folderName}/#{$gSettingAry[:zipf]}_#{inFileTag}.csv"
    }
    cGetFilePath.call( "statics" )
    CalcResultAry()
    SaveResultAry( cGetFilePath.call( "statics" ) )
    SaveLinkLoadAry( cGetFilePath.call( "linkLoad" ) )
    SaveContentAry( cGetFilePath.call( "content" ) )
    SaveRouterAry( cGetFilePath.call( "routerCacheHit" ) )
    SaveRouterReceiveQuery( cGetFilePath.call( "routerReceiveQuery" ) )
    SaveRouterCacheHitContent( cGetFilePath.call( "routerCacheHitContent" ) )
    SaveServerAry( cGetFilePath.call( "serverAry" ) )
    SaveUserAry( cGetFilePath.call( "user" ) )
  end
end

def Error( inErrorName, inLine ) # Error
  puts "ERROR Line " + inLine.to_s + " " + inErrorName
  exit
end

class Start

  def self.start
    cReadSettingFile = lambda{| inFilePath | # シミュレーションパラメータファイル読み込み
      return if inFilePath  == nil || !File.exist?( inFilePath  )
      puts "Read " + inFilePath
      open( inFilePath, "r" ){| f | $gSettingAry = eval( f.read ) }
      puts $gSettingAry
    }
    cSetSeed = lambda{| inSeed | # 乱数設定
      $gRandom = Random.new( inSeed )  
    }
    cReadTopologyFile = lambda{ # トポロジファイル読み込み
      return nil if File.exist?( "#{$gSettingAry[:briteFile]}.log" )
      inFilePath = "#{$gSettingAry[:briteFile]}"
      if inFilePath.index( ".brite" ) != nil
        return ReadBriteFile( inFilePath ) 
      else
        Error( "input file error", __LINE__)
      end
    }
    cWriteLogFile = lambda{| inFilePath, inRouterAry | # 配列ファイル書き込み
      return if File.exist?( inFilePath )
      writeRouterAry = Dijkstra( inRouterAry )
      open( inFilePath, "w" ){| f | f.write( writeRouterAry.inspect )}
    }
    cSetRouterAryFromLogFile = lambda{ |inFilePath| # 配列ファイル読み込み
      open( inFilePath ,"r" ){| f | ROUTER.SetRouterAry( eval( f.read ) ) }
      routerAry = ROUTER.GetRouterAry
      routerAry.each{|id,router| routerAry[id][:hopCountAry][id] = 0 }
    }
    cSetRouterType = lambda{ 
      ROUTER.GetRouterAry.each{| id, router | 
        router[ :routerType ] = $gSettingAry[ :routerType ] 
      }
    }  
    cSetSimulaterSetting = lambda{ # シミュレータ初期設定
      cRefreshSettingAry = lambda{| inRouterAry, inLinkAry |
        $gSettingAry[:linkWidth] *= 1.0
        $gSettingAry[:contentPacket] *= 1.0
        $gSettingAry[:queryPacket] *= 1.0
        $gSettingAry[:routerNum] = inRouterAry.map{|k,v| k}.length
        $gSettingAry[:linkNum] = inLinkAry.inject(0){|x1,v1| x1 += v1.length }
      }
      cSetBCViewerSetting = lambda{ # BCViewerログ出力初期設定
        return if $gSettingAry[:bcViewerLog] == nil
        LOG.SetFileName
        puts "LinkInfo"
        LOG.LinkInfo
        puts "ContentInfo"
        LOG.ContentInfo
      }
      puts "Start SetSimulaterSetting"
      SERVER.Init( ROUTER.GetRouterAry )
      CONTENT.SetPopularity
      USER.Init
      LINK.Init( ROUTER.GetRouterAry, USER.GetUserAry )
      STATICS.Init 
      ROUTER.Init
      cRefreshSettingAry.call( ROUTER.GetRouterAry, LINK.GetLinkAry )
    }
    cSaveResult = lambda{
      STATICS.SaveLog
    }
    startTime = Time.now
    cReadSettingFile.call( ARGV[ 0 ] )
    cSetSeed.call( $gSettingAry[ :seed ] )
    routerAry = cReadTopologyFile.call
    cWriteLogFile.call( "#{$gSettingAry[ :briteFile ]}.log", routerAry ) if routerAry != nil
    cSetRouterAryFromLogFile.call( "#{$gSettingAry[ :briteFile ]}.log" )    
    cSetRouterType.call
    cSetSimulaterSetting.call  
    EVENT.start
    puts "Time : " + ( Time.now - startTime ).to_s + " s"
    cSaveResult.call
    puts "Successful"
    puts "Time : " + ( Time.now - startTime ).to_s + " s"
  end
  
  def self.ReadBriteFile(inFilePass)
    puts "Start ReadBriteFile"
    routerAry=open(inFilePass).read.split("\n").drop(4).take_while{|i|i!=""}.length.times.inject({}){|x,i|x["R#{i}".to_sym]={
      :id            => "R#{i}".to_sym,
      :routingTblAry => {}, # key 到着ノードID, value 次ノードID
      :bcAry         => {}, # key 
      :hopCountAry   => {}, # key 到着ノードID, value ホップ数
      :cacheAry      => [], # キャッシュ済コンテンツ番号配列
      :edgeAry       => [], # 隣接ノードID配列
      :queryAry      => [], # コンテンツID, クエリリクエスト数
      :routerType    => nil,
      };x}
    open(inFilePass).read.split("\n").drop(4).drop_while{|i|i!=""}.drop(3).map{|i|[ ("R"+i.split[1]).to_sym,("R"+i.split[2]).to_sym]}.each{|x|2.times{|i|routerAry[x[i]][:edgeAry].push(x[1-i])}}
    routerAry
  end

  def self.Dijkstra( inRouterAry )
    puts "Start Dijkstra " + $gSettingAry[ :routerNum ].to_s
    inRouterAry.each{|id,router| # すべてのルータからルータへの最短経路を登録
      puts "Dijkstra #{id}" # 処理中のIDを表示
      temp=inRouterAry.inject({}){|x,kv|k,v=kv;x[k]={:cost=>1000000,:used=>false};x}
      temp[id][:cost] = 0
      while min = temp.select{|k,v| v[:used]==false && v[:cost]!=1000000 }.min{|a,b|a[1][:cost]<=>b[1][:cost]}
        min = min[ 0 ]
        temp[min][:used]=true
        inRouterAry[min][:edgeAry].select{|i|temp[min][:cost]+1<temp[i][:cost]}.each{|i|
          temp[i][:cost]=temp[min][:cost]+1
          inRouterAry[i][:routingTblAry][id]=min
          inRouterAry[id][:hopCountAry][i]=temp[i][:cost]}
      end }
    inRouterAry.each{|id,router| inRouterAry[id][:routingTblAry][id] = id }
  end
end

Start.start
