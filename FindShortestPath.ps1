# Requires PowerView

$Graph = @()
$Infinity = [int]::MaxValue
$Nodes = Get-NetUser | ForEach-Object { $_.samaccountname }
$Nodes += Get-NetComputer

ForEach($Node in $Nodes){
		$Vertex = New-Object PSObject
        $Vertex | Add-Member Noteproperty 'Name' $Node
        $Vertex | Add-Member Noteproperty 'Edges' @()
        $Vertex | Add-Member Noteproperty 'Distance' $Infinity
        $Vertex | Add-Member Noteproperty 'Visited' $False
		$Vertex | Add-Member Noteproperty 'Predecessor' $Null
        $Graph += $Vertex
}

function Invoke-Dijkstra ($Graph, $StartNode, $TargetNode){

    # Based on work by James Truher: https://jtruher3.wordpress.com/2006/10/16/dijkstra/

	$InitialNode = $Graph | Where-Object {$_.Name -Contains $StartNode}
	$InitialNode.Distance = 0
	$TargetNode = $Graph | Where-Object {$_.Name -Contains $TargetNode}
	
	For ($i = 0; $i -LT $Graph.Length; $i++){
	    $CurrentNode = $Graph | Where-Object {!$_.Visited} | Sort-Object Distance | Select-Object -First 1
		
		For ($j = 0; $j -LT $CurrentNode.Edges.Count; $j++){
		    $CurrentNodeEdge = $Graph | Where-Object {$CurrentNode.Edges[$j] -Contains $_.Name}
			If ($CurrentNodeEdge.Distance -GT $CurrentNode.Distance + 1){
			    $CurrentNodeEdge.Distance = $CurrentNode.Distance + 1
				$CurrentNodeEdge.Predecessor = $CurrentNode.Name
			}
		}
		
		$CurrentNode.Visited = $True
	}
	
	If ($TargetNode.Distance -LT $Infinity){
	    "$($InitialNode.Name) can reach $($TargetNode.name) in $($TargetNode.Distance) steps:"
		$Path = @()
		$R = $Graph | Where-Object {$TargetNode.Name -Contains $_.Name}
		$Path += $R.Predecessor
		For ($i = 0; $i -LT $TargetNode.Distance; $i++){
			$U = $Graph | Where-Object {$Path[$i] -Contains $_.Name}
			$Path += $U.Predecessor
		}
		
		[Array]::Reverse($Path)
		$Path += $TargetNode.Name
		$Path
		
		For ($j = 0; $j -LT $Path.Count; $j++){
		    
		}
	}
}

Get-NetComputers | ForEach-Object {
	
	Get-NetSession $_ | ForEach-Object {
		$Hostname = [System.Net.Dns]::GetHostByName((([System.Net.Dns]::GetHostByAddress($_.sesi10_cname.trim('\'))).hostname)).hostname
		$LoggedOnUser = $_.sesi10_username
		$CurrentNode = $Graph | Where-Object {$_.Name -Contains $Hostname}
		
		If($CurrentNode.Edges -NotContains $LoggedOnUser){
		    $CurrentNode.Edges += $LoggedOnUser
		}
		
		$Admins = Get-NetLocalGroup -Recurse $Hostname | Where-Object {$_.IsDomain -And !$_.IsGroup} | %{$_.AccountName}

        ForEach($Admin in $Admins){
		    $CurrentNode = $Graph | Where-Object {$_.Name -Contains $Admin.split('/')[1]}
			If($CurrentNode.Edges -NotContains $Hostname){
			    $CurrentNode.Edges += $Hostname
			}
		    
		}
	
	}
	
	
}

Invoke-Dijkstra $Graph Source Target
# Example: Invoke-Dijkstra $Graph Bob-User Steve-Admin
#$Graph
