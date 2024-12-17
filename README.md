# 채팅 구현 순서

1. myapp_web/channels/user_socket.ex 파일 생성
  1. 소켓설정
  2. room으로 시작하는 토픽을 MyappWeb.RoomChannel로 라우팅
  3. connect - 클라이언트 연결 시 호출
  4. id - 소켓 아이디

2. myapp_web/channels/room_channel.ex 파일 생성
   1. 채널 구현
   2. 라우팅 된 RoomChannel 설정
   3. 함수가 채널에 참여할 때 join함수 호출
   4. handle_in -> new_msg라는 새로운 이벤트 발생시 broadcast함수로 모두에게 뿌림

3. 라우터 설정

4. 컨트롤러 구현
   
5. phoenix template 구현