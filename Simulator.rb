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
$gRandom = Random.new( $gSettingAry[ :seed ] )  

require "./Statics.rb"

class ROUTER
  Dir::glob("./Router_*.rb").each{| f | 
    require "./#{f.gsub(".rb","").gsub("./","")}"  # モジュールを読み込む
    eval "extend #{f.gsub(".rb","").gsub("./","")}"# クラスメソッドとして定義
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

  def self.Init( inRouterAry )
    inRouterAry.keys.each{|i| 
      $gSettingAry[:userNum].times{|j|
        @@mUserAry[ "#{i}.U#{j}".to_sym]={
          routerId: i,
        }
      }
    }
    @@mUserAry.each{ |user_id, user |
      inRouterAry.each{| router_id, router |
        router[ :routingTblAry ][ user_id ] = router[ :routingTblAry ][ user[:routerId ] ]
      }
      inRouterAry[ user[ :routerId ] ][ :routingTblAry ][ user_id ] = user_id
    }    
  end
  
  def self.get_link_register_query( event )
    serverNodeId = CONTENT.GetContentAry[event[:contentId]][:serverNodeId]
    {
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

  def self.get_user_generate_query( in_time )
    {
      :time              => in_time,
      :message           => :userGenerateQuery,
      :contentId         => CONTENT.GetRandomContentId,
      :userNodeId        => USER.GetRandomUserNodeId,
    }
  end

  def self.GenerateQuery( event )
    link_register_query = get_link_register_query( event )
    EVENT.Register( link_register_query )
    time = event[:time] + $gSettingAry[ :queryGenerateTime ]
    user_generate_query = get_user_generate_query( time )
    EVENT.Register( user_generate_query ) if event[ :time ] <= $gSettingAry[ :simulationTime ]
  end

  def self.ReceiveContent( inEvent )

  end

end

class SERVER
  @@mServerAry = {}
  
  def self.GetServerAry() @@mServerAry end

  def self.Init( inRouterAry )
    cResetServerAry = lambda{| ioServerAry, inServerNum |
      inServerNum.times{| i |
        ioServerAry[ "S#{i}".to_sym ] = {
          routerId:     nil,
          serverNodeId: nil
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
        ioServerAry[ "S#{i}".to_sym ][ :serverNodeId ] = "#{routerId.to_s}.S#{i}".to_sym
      }
    }    
    cResetServerAry.call( @@mServerAry, $gSettingAry[ :serverNum ] )
    cSetServerRouterId.call( @@mServerAry, inRouterAry.keys )

    @@mServerAry.each{ |server_id, server |
      inRouterAry.each{| router_id, router |
        router[ :routingTblAry ][ server[:serverNodeId ] ] = router[ :routingTblAry ][ server[ :routerId ] ]
      }
      inRouterAry[ server[ :routerId ] ][ :routingTblAry ][ server[:serverNodeId] ] = server[ :serverNodeId ]
    }
    
  end
  def self.ReceiveQuery( inEvent )
    inEvent[ :contentSendTime ] = inEvent[ :time ]
    inEvent[ :message ] = :linkSendContent
    inEvent[ :nextNodeId ] = inEvent[ :serverNodeId ].to_s.split(".")[ 0 ].to_sym
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
    random = $gRandom.rand( @@total )
    contentId = self.FindContentIdFast( random )
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
    Error( "#{__FILE__} #{__LINE__} nextNodeId Error" ) if inEvent[ :nextNodeId ] == nil

    return EVENT.Register( inEvent ) if inEvent[ :nodeId ] == inEvent[ :nextNodeId ]
    inEvent[:time] = cCalcSendTime.call
    EVENT.Register( inEvent )
  end
  
  def self.RegisterContent( inEvent )
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
    Error( "#{__FILE__} #{__LINE__} nextNodeId Error") if inEvent[ :nextNodeId] == nil
    inEvent[:time] = cCalcSendTime.call
    EVENT.Register( inEvent )
  end
    
  def self.SendQuery( inEvent ) # Link.SendQuery()
    inEvent[:time] += $gSettingAry[ :queryPacket ] / $gSettingAry[ :linkWidth ]
    inEvent[:pastNodeId] = inEvent[ :nodeId ]
    inEvent[:nodeId] = inEvent[ :nextNodeId ]
    inEvent[:nextNodeId] = nil
    inEvent[:queryHopCount] += 1
    if inEvent[ :nodeId ].to_s.index( "S" ) != nil
      inEvent[:message] = :serverReceiveQuery
      EVENT.Register( inEvent )
    else
      inEvent[:message] = :routerReceiveQuery
      EVENT.Register( inEvent )
    end
  end
  def self.SendContent( inEvent ) # Link.SendContent()
    cSendContentToUserQ = lambda{
      inEvent[ :nodeId ].to_s.index( "U" ) != nil
    }
    cSendContentToUser = lambda{
      inEvent[ :message ] = :userReceiveContent
      inEvent[ :contentReceiveTime ] = inEvent[ :time ] + inEvent[ :contentPacketSize ] / $gSettingAry[ :linkWidth ]
      EVENT.Register( inEvent )
    }
    cSendConentToRouterQ = lambda{
      inEvent[ :nodeId ].to_s.index( "U" ) == nil
    }
    cSendConentToRouter = lambda{
      inEvent[ :message ] = :routerReceiveContent
      EVENT.Register( inEvent )
    }
    
    #実際の処理
    inEvent[:time] += $gSettingAry[ :queryPacket ] / $gSettingAry[ :linkWidth ]
    inEvent[:pastNodeId] = inEvent[:nodeId]
    inEvent[:nodeId] = inEvent[:nextNodeId]
    inEvent[:nextNodeId] = nil
    inEvent[:contentHopCount] += 1
    if cSendContentToUserQ.call
      cSendContentToUser.call
    elsif cSendConentToRouterQ.call
      cSendConentToRouter.call
    else
      ERROR( "#{__FILE__} #{__LINE__} Error LINK.SendContent")
    end
  end
end

class EVENT # 全てのイベントを管理
  @@mEventAry      = []
  @@mLogStr        = ""
  @@mLastEventTime = -1
  @@mEventCount    = -1  

  def self.SaveLog()
    open( $gSettingAry[:logFile], "w" ){|f|
      f.write( "#{$gSettingAry.inspect},\n#{@@mLogStr}" )
    }
  end  
  
  def self.Register( inEvent ) # イベントを登録
    binarySearch = lambda{ | time |  # 二分探索
      low = 0
      high = @@mEventAry.length - 1
      return 0 if high == -1
      while low <= high
        mid = ( low + high ) / 2
        case time  <=> @@mEventAry[ mid ][ :time ]
          when 0 then return mid
          when 1 then high = mid - 1
          when -1 then low = mid + 1
        end
      end
      low
    }
    pos = binarySearch.call( inEvent[ :time ] ) || @@mEventAry.length
    @@mEventAry[ pos, 0 ] = inEvent
  end

  def self.start()
    @@mEventAry[ 0 ] = USER.get_user_generate_query( time = 0 ) # 起動イベント
    puts "Simulation Loop Start"
    while ( event = @@mEventAry.pop ) != nil && event[:time] <= $gSettingAry[ :simulationStopTime ]
      Run( event )
    end
    puts "#{$gSettingAry[:simulationStopTime]} / #{$gSettingAry[:simulationStopTime]} #{@@mEventCount}"
  end

  def self.Run( event ) # イベントを実行
    @@mEventCount += 1
    @@mLastEventTime = event[:time]
    Error("#{__FILE__}#{__LINE__} EventTime #{event}") if @@mLastEventTime > event[ :time ]
    STATICS.ReadLogAry( event )
    puts "#{event[:time].to_i} / #{$gSettingAry[:simulationStopTime]} #{@@mEventAry.length} #{@@mEventCount}" if @@mEventCount & 4095 == 0
    p event if event[:queryId] == 1
    case event[:message]
      when :routerReceiveQuery   then ROUTER.ReceiveQuery( event )
      when :routerReceiveContent then ROUTER.ReceiveContent( event )
      when :routerCreateBc       then ROUTER.CreateBc( event )
      when :routerDeleteBc       then ROUTER.DeleteBc( event )
      when :routerDeleteBcAry    then ROUTER.DeleteBcAry( event )
      when :routerCacheHit       then ROUTER.CacheHit( event )
      when :routerCreateCache    then ROUTER.CreateCache( event )
      when :routerDeleteCache    then ROUTER.DeleteCache( event )
      when :userGenerateQuery    then USER.GenerateQuery( event )
      when :userReceiveContent   then USER.ReceiveContent( event )
      when :serverReceiveQuery   then SERVER.ReceiveQuery( event )
      when :linkRegisterQuery    then LINK.RegisterQuery( event )
      when :linkRegisterContent  then LINK.RegisterContent( event )
      when :linkSendQuery        then LINK.SendQuery( event )
      when :linkSendContent      then LINK.SendContent( event )
    else
      Error( "#{__FILE__} #{__LINE__} unknow event #event[:message]")
    end
  end  
end

def Error( inErrorStr )
  puts inErrorStr
  exit
end

class Main
  def self.start
    cReadSettingFile = lambda{| inFilePath | # シミュレーションパラメータファイル読み込み
      return if inFilePath  == nil || !File.exist?( inFilePath  )
      puts "Read " + inFilePath
      open( inFilePath, "r" ){| f | $gSettingAry = eval( f.read ) }
      puts $gSettingAry
    }
    cReadBriteFileQ = lambda{
      !File.exist?( "#{$gSettingAry[:briteFile]}.log" ) && File.exist?( "#{$gSettingAry[:briteFile]}" )
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
      USER.Init( ROUTER.GetRouterAry )
      LINK.Init( ROUTER.GetRouterAry, USER.GetUserAry )
      STATICS.Init 
      ROUTER.Init
      cRefreshSettingAry.call( ROUTER.GetRouterAry, LINK.GetLinkAry )
    }
    cSaveResult = lambda{
      STATICS.SaveLog
    }
    # 実際の処理
    startTime = Time.now
    cReadSettingFile.call( ARGV[ 0 ] ) if ARGV[ 0 ] != nil
    Main.ReadBriteFile                 if cReadBriteFileQ.call
    cSetRouterAryFromLogFile.call( "#{$gSettingAry[ :briteFile ]}.log" )
    cSetRouterType.call
    cSetSimulaterSetting.call  
    EVENT.start
    puts "Time : " + ( Time.now - startTime ).to_s + " s"
    cSaveResult.call
    puts "Successful"
    puts "Time : " + ( Time.now - startTime ).to_s + " s"
  end
  
  def self.ReadBriteFile
    inFilePath = $gSettingAry[:briteFile].to_s
    puts "Start ReadBriteFile #{inFilePath}"
    routerAry=open(inFilePath).read.split("\n").drop(4).take_while{|i|i!=""}.length.times.inject({}){|x,i|x["R#{i}".to_sym]={
      :id            => "R#{i}".to_sym,
      :routingTblAry => {}, # key 到着ノードID, value 次ノードID
      :bcAry         => {}, # key 
      :hopCountAry   => {}, # key 到着ノードID, value ホップ数
      :cacheAry      => [], # キャッシュ済コンテンツ番号配列
      :edgeAry       => [], # 隣接ノードID配列
      :queryAry      => [], # コンテンツID, クエリリクエスト数
      :routerType    => nil,
      };x}
    open(inFilePath).read.split("\n").drop(4).drop_while{|i|i!=""}.drop(3).map{|i|
      [ ("R"+i.split[1]).to_sym,("R"+i.split[2]).to_sym]
    }.each{|x|2.times{|i|routerAry[x[i]][:edgeAry].push(x[1-i])}}
    writeRouterAry = Dijkstra( routerAry )
    open( "#{inFilePath}.log", "w" ){| f | f.write( writeRouterAry.inspect )}
  end

  def self.Dijkstra( inRouterAry )
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

Main.start
