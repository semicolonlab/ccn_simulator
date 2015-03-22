module Router_IP
  def Router_IP_Init
  
  end

  def Router_IP_ReceiveQuery( inEvent )
    router = ROUTER.GetRouterAry[ inEvent[ :nodeId ] ]
    inEvent[ :message ] = :linkSendQuery
    inEvent[ :nextNodeId ] = router[ :routingTblAry ][ inEvent[ :serverNodeId ] ]
    EVENT.Register( inEvent )
  end
  
  def Router_IP_ReceiveContent( inEvent )
    router = ROUTER.GetRouterAry[ inEvent[ :nodeId ] ]
    inEvent[ :message ] = :linkSendContent
    inEvent[ :nextNodeId ] = router[ :routingTblAry ][ inEvent[ :userNodeId ] ]
    EVENT.Register( inEvent )
  end

  def Router_IP_CreateCache( inEvent )

  end
  
  def Router_IP_DeleteCache( inEvent )

  end
  
  def Router_IP_CacheHit( inEvent )

  end
  
  def Router_IP_CreateBc( inEvent )

  end
  
  def Router_IP_DeleteBc( inEvent )

  end
  
end
