# -*- coding: utf-8-*-  

import socket
import os,sys

if __name__=="__main__":  

	port=int(sys.argv[1])
	#print("")
	#print("\033[1;32;40m转发已经启动, Port:" + str(port) + ", Ctrl+c 进行退出\033[0m")

	socks = socket.socket(socket.AF_INET, socket.SOCK_STREAM) 
	socks.bind(("0.0.0.0",port)) 
	socks.listen(0)

	file_object = open('returnhtml')

	try:

		connection,address = socks.accept()

		#获得文件信息并返回

		msg = file_object.read( )

		connection.send(msg.encode()) 
		socks.settimeout(5)
		data=connection.recv(1024)   # 避免强制 reset , 通过超时结束 
		socks.settimeout(None)


		connection.close()

	except:
		pass


	file_object.close()





