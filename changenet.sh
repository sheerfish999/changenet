#!/bin/bash

###  yum install iptables

if [[ $# -lt 2 ]]
then

	echo 参数格式: 

	echo "1) ./changenet.sh  原目的IP 原目的端口 新目的IP:端口  (不能使用域名)"
	echo  "./changenet.sh IP1 800 IP2:80"
	echo "将本地对 IP1 800 的访问跳转到 IP2:80"
	echo ""
	echo "2) ./changenet.sh  原目的IP 原目的端口"
	echo  "./changenet.sh IP1 800"
	echo "将 对 IP1 800 的访问跳转到本地 returnhtml 的文件静态返回"
	echo ""
	echo "需要启用 iptables,  如出现任何网络异常, systemctl restart iptables   即可放弃任何修改进行重置" 
	echo "使用 iptables -L 查看 普通规则,  使用 iptables -D OUTPUT n 手动删除某个链中的规则" 
	echo "使用 iptables -t nat -L 查看 普通规则,  使用 iptables -t nat -D OUTPUT n 手动删除某个链中的规则" 

	exit 0

fi



dip=$1      # 目标IP
dport=$2		   #  目标PORT

if [[ $# -gt 2 ]]             # 存在 第三个参数
then
	newpos=$3
fi


# 屏蔽特征
#urlpath="/view/login/login.html"    # 屏蔽对于新连接没什么用, 直接会使用NAT跳转



##################### 退出函数

function toexit()
{
	#echo
	systemctl restart iptables
	echo -e "\033[1;32;40m正常退出.\033[0m"
	exit 0

}

#####################  等待任意键函数

function pause(){  
        read -n 1 -p "$*" INP  
        if [[ $INP != '' ]] ; then  
                echo -ne '\b \n'  
        fi  
}  
  

##################### 删除规则函数

function deleteiptables()
{

	#echo ""

	###################################    删除的对应防火墙规则     1/3   转发 


	line1=`iptables -t nat -L  OUTPUT | grep -n "Chain OUTPUT"   | awk -F ':' '{print $1}'  |head -n 1`
	line2=`iptables -t nat -L  OUTPUT| grep -n $1 |  awk -F ':' '{print $1}' |head -n 1`

	#line=$[$line2-$line1-1]
	#line=`expr $line2-$line1-1`  
	let "line=line2-line1-1"    #  这个方式更好

	#echo $line
	if [ $line -gt 0 ] 
	then

	    iptables -t nat -D OUTPUT $line
	   #echo "重置:已经删除预设转发规则1"

	   ###  如果没有删除规则,需要手动触发删除:
	   ###  iptables -t nat -L   #查看位置
	   ###  iptables -t nat -D OUTPUT 2 
	else
	    Tmp=1  #空操作
	    #echo "重置:没有设定预设转发规则1, 或删除出现问题"

	fi


	###################################    删除的对应防火墙规则     2/3   转发 


	line1=`iptables -t nat -L  POSTROUTING | grep -n "Chain POSTROUTING"   | awk -F ':' '{print $1}'  |head -n 1`
	line2=`iptables -t nat -L POSTROUTING | grep -n "MASQUERADE  all  --  anywhere             anywhere" |  awk -F ':' '{print $1}' |head -n 1`

	#line=$[$line2-$line1-1]
	#line=`expr $line2-$line1-1`  
	let "line=line2-line1-1"    #  这个方式更好

	#echo $line
	if [ $line -gt 0 ] 
	then

	    iptables -t nat -D POSTROUTING $line
	   #echo "重置:已经删除预设转发规则2"

	   ###  如果没有删除规则,需要手动触发删除:
	   ###  iptables -t nat -L   #查看位置
	   ###  iptables -t nat -D POSTROUTING 2 
	else
	    Tmp=1  #空操作
	    #echo "重置:没有设定预设转发规则2, 或删除出现问题"

	fi




	######################################  删除 DROP 规则

	if [[ $# -gt 3 ]]             # 存在 第四个参数,  这个参数未来即屏蔽参数   ------------  目前还未使用
	then

		#####  获得需要删除的对应防火墙规则     3/3   屏蔽对应特征的访问
		line1=`iptables -L OUTPUT | grep -n "Chain OUTPUT"   | awk -F ':' '{print $1}'   |head -n 1`
		line2=`iptables -L OUTPUT | grep -n $urlpath |grep DROP | awk -F ':' '{print $1}'  |head -n 1`

		#line=$[$line2-$line1-1]
		#line=`expr $line2-$line1-1`  
		let "line=line2-line1-1"    #  这个方式更好

		#echo $line
		if [ $line -gt 0 ] 
		then

		    iptables -D OUTPUT $line
		   #echo "重置:已经删除预设屏蔽规则"

		   ###  如果没有删除规则,需要手动触发删除:
		   ###  iptables -L   #查看位置
		   ###  iptables -D OUTPUT 1 
		else 
		    Tmp=1  #空操作
		    #echo "重置:没有设定预设屏蔽规则, 或删除出现问题"

		fi

	fi


}


#################  随机可用端口函数

function randomport()
{

    while(( 1 ))
    do
        port=$RANDOM    

	if [ $port -lt 65534 ] &&  [ $port -gt 10000 ]    ## 端口范围
	then

			hasport=`netstat -tln | grep $port | head -n 1 | awk '{print $4}'` 

			if [ "$hasport" == "" ]    #### 可用
			then
			   echo $port
			   break
			fi


	fi

    done

}


###########################   主要过程


### 初始化
touch /etc/iptables/iptables.rules
systemctl enable iptables
systemctl start iptables 
echo 1 > /proc/sys/net/ipv4/ip_forward



########  循环调用 nc 


while(( 1 ))
do
	port=`randomport`		 # 开启端口
	localport="127.0.0.1:"$port     # 本地地址

	if [[ $# -gt 2 ]]             # 存在 第三个参数
	then
		localport=$newpos
	fi
	echo $localport

	# 监控ctrl +c 退出信号, 删除转发规则, 并退出
	trap 'deleteiptables '$localport'; toexit ' INT     
	#echo ""

	####  设定规则   1/3  本地转发  ,  不支持字符特征规则
	iptables -t nat -A OUTPUT -p tcp -d $dip --dport $dport -j DNAT  --to $localport  
	#echo "设置:已经预设转发规则1"

	####  设定规则   2/3     防火墙的 IP 伪装 
	iptables -t nat -A POSTROUTING -j MASQUERADE            
	#echo "设置:已经预设转发规则2"


	#### 设定规则  3/3  屏蔽对应特征的访问      # 屏蔽对于新连接没什么用, 直接会使用NAT跳转   ####  如果添加, 务必注意开启 上访删除规则函数中的对应条目
	#iptables -A OUTPUT -p tcp -d $dip --dport $dport  -m string --string $urlpath --algo bm  -j DROP
	#echo "设置:已经预设屏蔽规则"

	#### nc 转入对应信息  , nc 太快容易出错
	# nc -l -p $port < returnhtml



	python tosend.py $port

	#### 结束后清理规则
	deleteiptables $localport


	####  等待输入任意键,  由于NAT映射的关系,  如果马上再次启动,  会直接将所有特征映射到转换后的请求  .  根据需要选择采用什么策略
	#echo ""
	#echo -e "\033[1;33;40m按任意键进行下次转发启动,  Ctrl+c 进行退出...\033[0m"
	#pause ''  

done









