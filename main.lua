PROJECT = "shineray650_ignition_lock"
VERSION = "0.2alpha"

log.info("main", PROJECT, VERSION)

--
_G.sys = require("sys")


local turn_on_pwd = {0, 0, 0, 0}
local turn_off_pwd = {1, 1, 1}
local input_code = {}
local max_input_length = 50
local BTN_PIN = 9
local button_timer_outtime = 10  -- button timer
local button_shake_time = 2
local button_long_time = 50

local button_detect = true
local button_state = false
local button_count = 0

--
if gpio.debounce then
    gpio.debounce(BTN_PIN, 5)
    log.info("debounce supported")
end

button = gpio.setup(BTN_PIN, function()
    if not button_detect then return end
    button_detect = false
    button_state = true
end,
gpio.PULLUP,
gpio.FALLING
)


function reset_input()
    input_code = {}
    log.info("reset input")
end

function copy(tb)
    local copy_tb = {}
    for k, v in pairs(tb) do
        copy_tb[k] = v
    end
    return copy_tb
end

RD_stall_pin = 18
RD_vcc_pin = 19
RD_stall_input_pin = 2
RD_vcc_input_pin = 3

LED = gpio.setup(12, 0, gpio.PULLUP)
RD_stall = gpio.setup(RD_stall_pin, 0, gpio.PULLUP)
RD_vcc = gpio.setup(RD_vcc_pin, 0, gpio.PULLUP)

RD_stall_input = gpio.setup(RD_stall_input_pin, nil)
RD_vcc_input = gpio.setup(RD_vcc_input_pin, nil)

local stall_status = 0 -- off, connect
local vcc_status = 0 -- off, connect
local key_status = 0 -- off
local pulse_width = 200


function flash_LED()
    LED(1)
    timer.mdelay(200)
    LED(0)
end

function turn_on_RD(out_pin, input_pin, pin_name)
    log.info(string.format("try turn %s on", pin_name))
    if 0 == gpio.get(input_pin) then
        local try_count = 1
        while 0 == gpio.get(input_pin) and try_count < 5 do
            log.info(string.format("try %d time", try_count))
            gpio.set(out_pin, 1)
            timer.mdelay(pulse_width)
            gpio.set(out_pin, 0)
            try_count = try_count + 1
            timer.mdelay(200)  -- waitting for the RD action
        end
        if 0 == gpio.get(input_pin) then
            log.info(string.format("turn on %s failed", pin_name))
        else
            log.info(string.format("turn on %s successfully", pin_name))
            flash_LED()
        end
    else
        log.info(string.format("%s already on", pin_name))
    end
end

function turn_off_RD(out_pin, input_pin, pin_name)
    log.info(string.format("try turn %s off", pin_name))
    if 1 == gpio.get(input_pin) then
        local try_count = 1
        while 1 == gpio.get(input_pin) and try_count < 10 do
            log.info(string.format("try %d time", try_count))
            gpio.set(out_pin, 1)
            timer.mdelay(pulse_width)
            gpio.set(out_pin, 0)
            try_count = try_count + 1
            timer.mdelay(200)  -- waitting for the RD action
        end
        if 1 == gpio.get(input_pin) then
            log.info(string.format("turn off %s failed", pin_name))
        else
            log.info(string.format("turn off %s successfully", pin_name))
            flash_LED()
        end
    else
        log.info(string.format("%s already off", pin_name))
    end
end

function update_lock_status()
    stall_status = gpio.get(RD_stall_input_pin)
    vcc_status = gpio.get(RD_vcc_input_pin)

    if 1 == stall_status and 1 == vcc_status then
        key_status = 1
    elseif 0 == stall_status and 0 == vcc_status then
        key_status = 0
    else
        key_status = -1
        log.info("ERROR status!!")
    end
end

function turn_on_lock()
    turn_on_RD(RD_stall_pin, RD_stall_input_pin, "stall")
    turn_on_RD(RD_vcc_pin, RD_vcc_input_pin, "vcc")
    update_lock_status()
end

function turn_off_lock()
    turn_off_RD(RD_vcc_pin, RD_vcc_input_pin, "vcc")
    turn_off_RD(RD_stall_pin, RD_stall_input_pin, "stall")
    update_lock_status()
end

function check_equal_table(t1, t2)
    local len1 = #t1
    local len2 = #t2
    if (len1 ~= len2) then
        return false
    end

    local i = 1
    for i = 1, len1, 1 do
        if t1[i] ~= t2[i] then
            return flase
        end
    end
    return true
end

function get_input_code()
    if button_state then
        if button() == 0 then
            button_count = button_count + 1
            if button_count > button_long_time then 
                --print("long pass")
            end
        else
            if button_count < button_shake_time then
            else
                if button_count < button_long_time then
                    print("short pass")
                    input_code[#input_code+1] = 0
                else
                    print("long pass")
                    input_code[#input_code+1] = 1
                end
                log.info(table.concat(input_code, ","))

                update_lock_status()

                if 0 == key_status then
                    if #input_code == #turn_on_pwd then
                        if check_equal_table(turn_on_pwd, input_code) then
                            log.info("correct turn on pwd!")
                            turn_on_lock()
                            log.info("*************** TURN ON ***************")
                            reset_input()
                        end
                    elseif #input_code >= max_input_length then
                        log.info("input_error")
                        reset_input()
                    end
                elseif 1 == key_status then
                    if #input_code == #turn_off_pwd then
                        if check_equal_table(turn_off_pwd, input_code) then
                            log.info("correct turn off pwd!")
                            turn_off_lock()
                            log.info("*************** TURN OFF ***************")
                            reset_input()
                        end
                    elseif #input_code >= max_input_length then
                        log.info("input_error")
                        reset_input()
                    end
                end
            end
            button_count = 0
            button_state = false
            button_detect = true
        end
    end
end

local button_timer = sys.timerLoopStart(get_input_code, button_timer_outtime)

local input_code_clone = copy(input_code)
sys.taskInit(function()
    while 1 do
        input_code_clone = copy(input_code)
        sys.wait(2000)
        if check_equal_table(input_code, input_code_clone) then
            log.info("time out")
            reset_input()
        end
    end
end)

timer.mdelay(500)
update_lock_status()
turn_off_lock()

sys.run()
