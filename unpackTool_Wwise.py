import os
import time
import queue
import logging
import argparse
import subprocess
import multiprocessing
import psutil
import traceback
from pathlib import Path
import pdb
def add_numbers(a, b):    # 设置断点
    # pdb.set_trace()
    result = a + b
    # return result
LOW_THRESHOLD = 40
HIGH_THRESHOLD = 80
def adjust_processes(processes, percent):
    if percent < LOW_THRESHOLD:
        return processes + 2
    elif percent > HIGH_THRESHOLD:
        return processes - 2
    else:
        return processes
def get_optimal_processes():
    # output_folder = Path(output_folder)
    cpu_percent = psutil.cpu_percent()
    memory_percent = psutil.virtual_memory().percent
    # disk_io_percent = psutil.disk_usage(output_folder).percent
    optimal_processes = os.cpu_count()
    optimal_processes = adjust_processes(optimal_processes, cpu_percent)
    optimal_processes = adjust_processes(optimal_processes, memory_percent)
    # optimal_processes = adjust_processes(optimal_processes, disk_io_percent)
    return max(1, optimal_processes)
class WwiseBankConverter:
    def __init__(self, input_folder, output_folder, temp_folder, tools_folder):
        self.input_folder = Path(input_folder)
        self.output_folder = Path(output_folder)
        self.temp_folder = Path(temp_folder)
        self.tools_folder = Path(tools_folder)
        self.process_map = {
            1: self.process_pck,
            2: self.process_bnk,
            3: self.process_wem,
            4: self.process_xml
        }
    def process_file(self, file_queue):
        while not file_queue.empty():
            try:
                priority, file = file_queue.get()
                if not file.exists():
                    logging.warning(f"File does not exist: {file}")
                    continue
                logging.info(f"Start processing file: {file}")
                process_func = self.process_map.get(priority)
                if process_func:
                    result = process_func(file)
                else:
                    logging.warning(f"Unsupported file type: {file}")
                    result = None
                logging.info(f"Finish processing file: {file}")
            except Exception as e:
                logging.error(f"Error processing file: {file}\n{traceback.format_exc()}")
    def run_command(self, command, file):
        stdout = stderr = subprocess.DEVNULL
        result = subprocess.run([str(path) for path in command], stdout=stdout, stderr=stderr)
        # print(f"Command result: {result}")
        new_file = file.with_suffix(file.suffix + '.done')
        try:
            file.rename(new_file)
        except FileNotFoundError as e:
            logging.warning(f"File operation error")  # :{e}
    def process_pck(self, file):
        output_subfolder = self.input_folder / "PCK2BNK" / file.stem
        os.makedirs(output_subfolder, exist_ok=True)
        command = [self.tools_folder / "quickbms.exe", "-k", "-q", "-Y", self.tools_folder / "wwise_pck_extractor.bms", file, output_subfolder]
        self.run_command(command, file)
    def process_bnk(self, file):
        command = [self.tools_folder / "bnkextr.exe", "/nodir", file]
        self.run_command(command, file)
    def process_wem(self, file):
        ogg_file = self.output_folder / file.with_suffix('.ogg')
        if ogg_file.exists():
            logging.info(f"Ogg file already exists: {ogg_file}")
            file.rename(file.with_suffix(file.suffix + '.done'))
        else:
            relative_path = file.relative_to(self.input_folder)
            output_file = self.output_folder / relative_path.with_suffix('.ogg')
            logging.info(f'relative_path:{relative_path} - output_file:{output_file}')
            output_file.parent.mkdir(parents=True, exist_ok=True)
            wav_file = str(file.with_suffix('.wav'))
            command = [self.tools_folder / "vgmstream-cli.exe", "-o", wav_file, file]
            self.run_command(command, file)
            command = [self.tools_folder / "ffmpeg.exe", "-i", wav_file, str(output_file)]
            self.run_command(command, file)
            command = os.remove(wav_file)
            logging.info(f'WAV-del:{command}')
    def process_xml(self, file):
        tree = ET.parse(file)
        root = tree.getroot()
    def update_resource(self, result):
        logging.info(f"update-------- {result}")
def main():
    a = 10
    b = 20
    result = add_numbers(a, b)
    print(f"The result is {result}")
    parser = argparse.ArgumentParser(description="unpackTools_Wwise")
    args_config = {
        "input": {"default": "wwiseBank"},
        "output": {"default": "ogg"},
        "temp": {"default": "temp"},
        "tools": {"default": "tools"},
        "processes": {"type": int, "default": get_optimal_processes()}
    }
    for arg, config in args_config.items():
        parser.add_argument(f"--{arg}", **config)
    args = parser.parse_args()
    logging.basicConfig(level=logging.INFO, format="%(asctime)s %(levelname)s %(message)s")
    converter = WwiseBankConverter(args.input, args.output, args.temp, args.tools)
    priority_map = {".pck": 1, ".bnk": 2, ".wem": 3, ".xml": 4}
    wem_need_process = set()
    for priority in sorted(priority_map.values()):
        file_queue = multiprocessing.Manager().Queue()
        file_count = 0
        if priority == priority_map.get(".wem"):
            ogg_files = set(file.stem for file in Path(args.output).rglob('*.ogg'))
            wem_files = set(file.stem for file in Path(args.input).rglob('*.wem'))
            wem_need_process_stems = wem_files - ogg_files
            wem_need_process = set(file for file in Path(args.input).rglob('*.wem') if file.stem in wem_need_process_stems)
            for file in wem_need_process:
                file_queue.put((priority, file))
                file_count += 1
                print(f"Queue size after adding file: {file_queue.qsize()} - {file}")
        else:
            for file in converter.input_folder.rglob("*"):
                if priority_map.get(file.suffix) == priority:
                    file_queue.put((priority, file))
                    file_count += 1
                    print(f"Queue size after adding file: {file_queue.qsize()} - {file}")
        processes = []
        for _ in range(args.processes):
            logging.info(f"Start process: {_}")
            p = multiprocessing.Process(target=converter.process_file, args=(file_queue,))
            p.start()
            processes.append(p)
        check_interval = max(1, file_count // 100)
        processed_files = 0
        start_time = time.time()
        while not file_queue.empty():
            for _ in range(check_interval):
                if file_queue.empty():
                    break
                time.sleep(0.1)
                processed_files += 1
            if processed_files % check_interval == 0 or time.time() - start_time > 10:
                while any(p.is_alive() for p in processes):
                    time.sleep(0.1)
                start_time = time.time()
    logging.info("Convert Done!")
    input('PAUSE')
if __name__ == '__main__':
    multiprocessing.freeze_support()
    main()