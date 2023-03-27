const express =require("express");
var http=require("http");
const app=express();
const port=process.env.PORT||3000;
var server=http.createServer(app);
const mongoose=require("mongoose");
const Room=require('./models/Room');
var io=require("socket.io")(server);
const getWord=require('./api/getWord');
const { isTypedArray } = require("util/types");
// middleware
app.use(express.json());

// connect to our mongoDB
const DB='mongodb+srv://manav:manav69@cluster0.4hdiyeb.mongodb.net/?retryWrites=true&w=majority';

mongoose.connect(DB).then(()=>{
console.log('Connection Successful');
}).catch((e)=>{
    console.log(e);
}
)


io.on('connection',(socket)=>{
    // console.log('yes');
    // console.log('connected');
    // CREATE GAME
    socket.on('create-game',async({nickname,name,occupancy,maxround})=>{
        try{
             const existingRoom=await Room.findOne({name});
             if(existingRoom)
             {
                socket.emit('notCorrectGame','Room with that name already exist');
                return;
             }
            //  console.log('yes');
             let room=new Room();
             const word=getWord();
             room.word=word;
             room.name=name;
             room.occupancy=occupancy;
             room.maxround=maxround;
             
             let player={
                socketID:socket.id,
                nickname,
                isPartyLeader:true
             }
             room.players.push(player);
            //  console.log(room);
             room =await room.save();
             socket.join(name);
             io.to(name).emit('updateRoom',room);

        }
        catch(err)
        {
         console.log(err);
        }
    });
    // JOIN GAME CALLBACK
    socket.on('join-game',async({nickname,name})=>{
        try{
               let room=await Room.findOne({name});
               if(!room)
               {
                socket.emit('notCorrectGame','Please enter a valid room name');
                return;
               }
               if(room.isJoin==true)
               {
                let player={
                    socketID:socket.id,
                    nickname
                }
                room.players.push(player);
                socket.join(name);
                if(room.players.length===room.occupancy)
                {
                    room.isJoin=false;
                }
                room.turn=room.players[room.turnIndex];
                room=await room.save();
                // console.log(room);
                io.to(name).emit('updateRoom',room);
               }
               else
               {
                socket.emit('notCorrectGame','The game is in progress please try later');
               }
        }
        catch(e)
        {
            console.log(e);
        }
    })
     
    // white board sockets
    socket.on('paint',(data)=>{
try
       { 
        
        // console.log(details);
        // console.log(data.roomName);
        io.to(data.roomName).emit('points', {details: data.details});}
       catch(e)
       {
        console.log(e);
       }
        // console.log(details);
    })


    // color-socket
    socket.on('color-change',({color,roomName})=>{
        io.to(roomName).emit('color-change',color);
    })

    // stroke socket
    socket.on('stroke-width',({strokeWidth,roomName})=>{

        // console.log(roomName);
        io.to(roomName).emit('stroke-width',strokeWidth);
    })


    // clear screen
    socket.on('clear-screen',(roomName)=>{
        
        io.to(roomName).emit('clear-screen','');
    })
    

    // message socket
    socket.on('msg', async (data)=>{
        // console.log(data.username);c
        
        
         const gussedUserCtr=JSON.parse(JSON.stringify(data)).gussedUserCtr;
        console.log(gussedUserCtr);


        try{
                if(data.msg==data.word)
                {
                    let room=await Room.find({name: data.roomName});
                    let userPlayer=room[0].players.filter(
                        (player)=>player.nickname==data.username
                    )
                    if(data.timeTaken!==0)
                    {
                        userPlayer[0].points+=Math.round((200/data.timeTaken)*10);
                    }
                    room =await room[0].save();
                    // console.log(data.roomName);
                    io.to(data.roomName).emit('msg',{
                        username: data.username,
                        msg: 'Guessed it!',
                        gussedUserCtr: gussedUserCtr+1,
                    })
                    socket.emit('close-input','');
                }
                else
                {
                    io.to(data.roomName).emit('msg',{
                        username: data.username,
                        msg: data.msg,
                        guessedUserCtr: gussedUserCtr,
                      })
                }
            
        }
        catch(e)
        {
console.log(e);
        }
    })

    // change turn socket
 socket.on('change-turn', async (name)=>{
    try{
  let room=await Room.findOne({name});
  console.log(room);
  let idx=room.turnIndex;
  if(idx+1===room.players.length)
  {
    room.currentRound+=1;
  }
  if(room.currentRound<=room.maxround)
  {
    const word=getWord();
    room.word=word;
    room.turnIndex=(idx+1)%room.players.length;
    room.turn=room.players[room.turnIndex];
    console.log(room.players[room.turnIndex]);
    room=await room.save();
    io.to(name).emit('change-turn',room);
  }
  else
  {
    // show the leaderboard
    io.to(name).emit('show-leaderboad',room.players);
  }
    }
    catch(e)
    {
console.log(e);
    }
 })

 socket.on('updateScore', async(name)=>{
    try{
           const room =await Room.findOne({name});
           io.to(name).emit('updateScore',room);
    }
    catch(e)
    {
        console.log(e);
    }
 })



 socket.on('disconnect',async()=>{
    try{
            let room =await Room.findOne({"players.socketID":socket.id});
            for(let i=0;i<room.players.length;i++)
            {
                  if(room.player[i].socketID===socket.id)
                  {
                    room.players.splice(i,1);
                    break;
                  }
            }
            room= await room.save();
            if(room.players.length===1)
            {
                socket.broadcast.to(room.name).emit('show-leaderboard',room.players);
            }
            else
            {
                socket.broadcast.to(room.name).emit('user-disconnected',room);
            }
    }
    catch(e)
    {
        console.log(e); 
    }
 })
})







server.listen(port,"0.0.0.0",()=>{
    console.log('Server started and running on port'+ port);
})