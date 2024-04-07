// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract MultiSigWallet {
    address[] public owners;//list of owners 
    uint public numConfirm;//minimum number to confirm a transaction
    //basic information about the transaction
    struct Transaction{
    address to;
    uint value;
    bool executed;
    }

    mapping (uint=>mapping (address=>bool)) isConfirmed;
    mapping (address=>bool) isOwner;
    //list of transaction : 1) pending or 2) executed
    Transaction[] public transactions;

    event TransactionSubmitted(uint transactionId,address sender,address receiver,uint amount);
    event TransactionConfirmed(uint transactionId);
    event TransactionExecuted(uint transactionId);

     modifier onlyOwner() {
        require(isOwner[msg.sender], "Not an owner");
        _;
    }
    //initializing owners and numconfirm and also checking the base criteria's to not break the logic of multisign
    constructor(address[] memory _owners,uint _numConfirmationRequired){
    require(_owners.length>1,"owners required must grater than 1");
    require( _numConfirmationRequired>0 &&  _numConfirmationRequired<=_owners.length,"Num of confirmation is not sync with num of owner");
    numConfirm=_numConfirmationRequired;

   for(uint i=0;i<_owners.length;i++){
    require(_owners[i]!=address(0),"Invalid Owner");
    owners.push(_owners[i]);
    isOwner[_owners[i]]=true;
    }

    }
    /** 
     * @param _to :sender address to hum we are sending the amount
     *
     */
    function submitTrnsaction(address _to) public payable {
        require(_to!=address(0),"Invalid ");
        require(msg.value>0 ,"Transfer amount must be grater than 0 ");
        uint transactionId=transactions.length;

        transactions.push(Transaction({
            to:_to,
            value:msg.value,
            executed:false
            }));

        emit TransactionSubmitted( transactionId,msg.sender,_to,msg.value);
    }
    /***
     * desc: confirms the transaction for a owner if only he has not previously confirmed the transaction and also checks if minimum number of confirmation is gather to execute the transaction 
     */
    function confirmTransaction(uint _transactionId) public onlyOwner{
    require(_transactionId<transactions.length,"Invalid transaction");
    require(!isConfirmed[_transactionId][msg.sender],"Transaction is already confirm by owner");
    isConfirmed[_transactionId][msg.sender]=true;
    emit  TransactionConfirmed(_transactionId);

    if(isTransactionConfirmed( _transactionId)){
      executeTransaction(_transactionId);
    }
    }
    /***
     * desc: checks if the total number of owners confirmed the transaction is more than numConfirm
     */
    function isTransactionConfirmed(uint _transactionId)public view returns (bool){
         require(_transactionId<transactions.length,"Invalid transaction");
         uint confirmation;
         for(uint i=0;i<numConfirm;i++){
             if(isConfirmed[_transactionId][owners[i]]){
              confirmation++;
             }
         }
         return confirmation>=numConfirm;
    }
    /***
     * desc: if all the confirmation are made then the transaction is executed
     */
    function executeTransaction(uint _transactionId) public  payable {
         require(_transactionId<transactions.length,"Invalid transaction");
         require(!transactions[_transactionId].executed,"Transaction is already executed");
       
         (bool success,)= transactions[_transactionId].to.call{value:transactions[_transactionId].value}("");

        require(success,"Transaction Execution Failed ");
        transactions[_transactionId].executed=true;
        emit TransactionExecuted(_transactionId);
    }

}