module directoryStateMachineCPU(
    input operation, hit, input[1:0] cpuInitialState, 
    output reg readMissOnBus, writeMissOnBus, invalidateOnBus, dataWriteBack, 
    output reg [1:0] cpuNewState
    );
//
//invalidate
//shared
//modified
//escrita 1, leitura 0
localparam INVALID = 2'b01, SHARED = 2'b10, MODIFIED = 2'b11;

initial begin
    readMissOnBus <= 1'b0;
    writeMissOnBus <= 1'b0;
    invalidateOnBus <= 1'b0;
    dataWriteBack <= 1'b0;
end

always @(*) begin
    case(cpuInitialState)
        INVALID: begin
            if(operation == 1'b0) begin //read
                cpuNewState <= SHARED;
                readMissOnBus <=  1'b1;
                writeMissOnBus <= 1'b0;
                invalidateOnBus <= 1'b0;
                dataWriteBack <= 1'b0;
            end 
            else if(operation==1'b1) begin //write
                cpuNewState <= MODIFIED;
                writeMissOnBus <= 1'b1;
                readMissOnBus <= 1'b0;
                invalidateOnBus <= 1'b0;
                dataWriteBack <= 1'b0;
            end
        end
        
        SHARED: begin
            case({operation, hit}) 
                2'b00: begin //read miss PRA ESCRITA SEMPRE MODIFIED
                    cpuNewState <= SHARED;
                    writeMissOnBus <= 1'b0;
                    invalidateOnBus <= 1'b0;
                    readMissOnBus <= 1'b1;
                    dataWriteBack <= 1'b0;
                end

                2'b01: begin //read hit
                    cpuNewState <= SHARED;
                    writeMissOnBus <= 1'b0;
                    invalidateOnBus <= 1'b0;
                    readMissOnBus <= 1'b0;
                    dataWriteBack <= 1'b0;
                end

                2'b10: begin // write miss
                    cpuNewState <= MODIFIED;
                    writeMissOnBus <= 1'b1;
                    invalidateOnBus <= 1'b0;
                    readMissOnBus <= 1'b0;
                    dataWriteBack <= 1'b0;
                end

                2'b11: begin // write hit
                    cpuNewState <= MODIFIED;
                    writeMissOnBus <= 1'b0;
                    invalidateOnBus <= 1'b1;
                    readMissOnBus <= 1'b0;
                    dataWriteBack <= 1'b0;
                end
            endcase
        end

        MODIFIED: begin
            case({operation, hit}) 
                2'b00: begin //read miss PRA ESCRITA SEMPRE MODIFIED
                    cpuNewState <= SHARED;
                    writeMissOnBus <= 1'b0;
                    invalidateOnBus <= 1'b0;
                    readMissOnBus <= 1'b1;
                    dataWriteBack <= 1'b1;
                end

                2'b01: begin //read hit
                    cpuNewState <= MODIFIED;
                    writeMissOnBus <= 1'b0;
                    invalidateOnBus <= 1'b0;
                    readMissOnBus <= 1'b0;
                    dataWriteBack <= 1'b0;
                end

                2'b10: begin // write miss
                    cpuNewState <= MODIFIED;
                    writeMissOnBus <= 1'b1;
                    invalidateOnBus <= 1'b0;
                    readMissOnBus <= 1'b0;
                    dataWriteBack <= 1'b1;
                end

                2'b11: begin // write hit
                    cpuNewState <= MODIFIED;
                    writeMissOnBus <= 1'b0;
                    invalidateOnBus <= 1'b0;
                    readMissOnBus <= 1'b0;
                    dataWriteBack <= 1'b0;
                end
            endcase
        end

    endcase
end

endmodule


module directoryStateMachineBus(
    input fetch, invalidate, 
    input[1:0] initialState, 
    output reg [1:0] busNewState, output reg busWriteBack, abortMemAccess);

localparam NONEMESSAGE = 2'b00, INVALID = 2'b01, SHARED = 2'b10, MODIFIED = 2'b11;

always @(*) begin
case (initialState)
    SHARED: begin
        if(invalidate == 1'b1)begin
            busNewState <= INVALID;
            busWriteBack <= 1'b0;
        end
    end

    INVALID: begin
        busNewState <= INVALID;
        busWriteBack<= 1'b0;
    end

    MODIFIED: begin
        if(fetch == 1'b1 & invalidate == 1'b1)begin
            busNewState <= INVALID;
            busWriteBack<= 1'b1;
        end 
        if(fetch == 1'b1) begin
            busNewState <= MODIFIED;
            busWriteBack <= 1'b1;
        end
    end
endcase
end
endmodule


module directoryFSM(
    input requester, readMiss, invalidate, writeMiss, dataWriteBack,
    input[1:0] initialState, input[3:0] ownersSharers, 
    output reg[1:0] directoryNewState, output reg directoryFetch, 
    directoryInvalidate, dataValueReply, output reg [3:0] dataSharers
    );

localparam NONEMESSAGE = 2'b00, UNCACHED = 2'b01, SHARED = 2'b10, MODIFIED = 2'b11;

always @(*) begin
    case (initialState)
        SHARED: begin
            if(readMiss == 1'b1) begin //readmiss
                dataValueReply <= 1'b1;
                directoryFetch <= 1'b0;
                directoryInvalidate <= 1'b0; 
                directoryNewState <= SHARED;
                if (requester == 1'b1) begin
                    dataSharers <= {ownersSharers[3:2],1'b1,ownersSharers[0]};
                end
                else if(requester == 1'b0) begin
                    dataSharers <= {ownersSharers[3:1],1'b1};
                end
            end
            if(writeMiss == 1'b1) begin //write miss
                dataValueReply <= 1'b1;
                directoryFetch <= 1'b0;
                directoryInvalidate <= 1'b1; 
                directoryNewState <= MODIFIED;
                if (requester == 1'b1) begin
                    dataSharers <= {ownersSharers[3:2],2'b10};
                end
                else if(requester == 1'b0) begin
                    dataSharers <= {ownersSharers[3:2],2'b01};
                end
            end
        end
        UNCACHED: begin //uncached
            if(readMiss == 1'b1) begin //readmiss
                dataValueReply <= 1'b1;
                directoryFetch <= 1'b0;
                directoryInvalidate <= 1'b0; 
                directoryNewState <= SHARED;
                if (requester == 1'b1) begin
                    dataSharers <= {ownersSharers[3:2],2'b10};
                end
                else if(requester == 1'b0) begin
                    dataSharers <= {ownersSharers[3:2],2'b01};
                end
            end
            if(writeMiss == 1'b1) begin
                dataValueReply <= 1'b1;
                directoryFetch <= 1'b0;
                directoryInvalidate <= 1'b0; 
                directoryNewState <= MODIFIED;
                if (requester == 1'b1) begin
                    dataSharers <= {ownersSharers[3:2],2'b10};
                end
                else if(requester == 1'b0) begin
                    dataSharers <= {ownersSharers[3:2],2'b01};
                end
            end
        end
        MODIFIED: begin
            if(readMiss == 1'b1) begin //readmiss
                dataValueReply <= 1'b1;
                directoryFetch <= 1'b1;
                directoryInvalidate <= 1'b0; 
                directoryNewState <= SHARED;
                if (requester == 1'b1) begin
                    dataSharers <= {ownersSharers[3:2],1'b1,ownersSharers[0]};
                end
                else if(requester == 1'b0) begin
                    dataSharers <= {ownersSharers[3:1],1'b1};
                end
            end
            else if(writeMiss == 1'b1) begin
                dataValueReply <= 1'b1;
                directoryFetch <= 1'b1;
                directoryInvalidate <= 1'b1; 
                directoryNewState <= MODIFIED;
                if (requester == 1'b1) begin
                    dataSharers <= {ownersSharers[3:2],2'b10};
                end
                else if(requester == 1'b0) begin
                    dataSharers <= {ownersSharers[3:2],2'b01};
                end
            end
            else if (dataWriteBack == 1'b1) begin
                dataValueReply <= 1'b0;
                directoryFetch <= 1'b0;
                directoryInvalidate <= 1'b0; 
                directoryNewState <= UNCACHED;
                dataSharers <= {ownersSharers[3:2],2'b00};
            end
        end
        default: begin
            
        end
    endcase
end
endmodule
