import argparse
import os
from pydub import AudioSegment

def convert_wav_to_mp3(wav_file_path, mp3_file_path, bitrate="320k"):
    # Load the WAV file
    audio = AudioSegment.from_wav(wav_file_path)

    # Export the audio as MP3 with the specified bitrate
    audio.export(mp3_file_path, format="mp3", bitrate=bitrate)
    print(f"Conversion successful! MP3 saved at: {mp3_file_path}")

def main():
    # Set up argument parser
    parser = argparse.ArgumentParser(description="Convert WAV files to MP3 format with specified bitrate.")
    
    parser.add_argument("wav_file", help="Path to the input WAV file.")
    parser.add_argument("-o", "--output", help="Path to save the output MP3 file. Default is the same as input with .mp3 extension.")
    parser.add_argument("-b", "--bitrate", default="320k", help="Bitrate for the output MP3 file (default: 320k).")

    # Parse arguments
    args = parser.parse_args()

    # Determine the output file path
    if args.output:
        mp3_file_path = args.output
    else:
        base, _ = os.path.splitext(args.wav_file)
        mp3_file_path = f"{base}.mp3"

    # Convert WAV to MP3
    convert_wav_to_mp3(args.wav_file, mp3_file_path, args.bitrate)

if __name__ == "__main__":
    main()

