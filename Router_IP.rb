module Router_IP
  def Router_IP_Init
  
  end

  def Router_IP_ReceiveQuery( inEvent ) 
    if inEvent[:nodeId] == inEvent[:serverRouterId]
      inEvent[:message] = :linkSendQuery
      inEvent[:nextNodeId] = inEvent[:serverNodeId]
      EVENT.Register( inEvent )
      return
    else 
      inEvent[ :message ] = :linkSendQuery
      inEvent[ :nextNodeId ] = ROUTER.GetRouterAry[ inEvent[ :nodeId ] ][ :routingTblAry ][ inEvent[ :serverRouterId ] ]
      EVENT.Register( inEvent )
      return
    end
  end
  
  def Router_IP_ReceiveContent( inEvent )
    if inEvent[ :nodeId ] == inEvent[:userRouterId]
      inEvent[ :message ] = :linkSendContent
      inEvent[ :nextNodeId ] = inEvent[ :userNodeId ]
      EVENT.Register( inEvent )
      return
    else
      inEvent[ :message ] = :linkSendContent
      inEvent[ :nextNodeId ] = ROUTER.GetRouterAry[ inEvent[ :nodeId ] ][ :routingTblAry ][ inEvent[ :userRouterId ] ]
      EVENT.Register( inEvent )
      return
    end
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