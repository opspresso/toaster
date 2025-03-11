#!/usr/bin/env python3

import os
import configparser
import subprocess
import click
from toast.plugins.base_plugin import BasePlugin
from toast.plugins.utils import select_from_list

class EnvPlugin(BasePlugin):
    """Plugin for 'env' command - manages AWS profiles."""

    name = "env"
    help = "Manage AWS profiles"

    @classmethod
    def execute(cls, **kwargs):
        try:
            # AWS credentials 파일 경로
            credentials_path = os.path.expanduser("~/.aws/credentials")

            # 파일이 존재하는지 확인
            if not os.path.exists(credentials_path):
                click.echo(f"AWS credentials 파일을 찾을 수 없습니다: {credentials_path}")
                return

            # configparser를 사용하여 credentials 파일 파싱
            config = configparser.ConfigParser()
            config.read(credentials_path)

            # 프로필 목록 추출
            profiles = config.sections()

            if not profiles:
                click.echo("AWS credentials 파일에 프로필이 없습니다.")
                return

            # 현재 기본 프로필 가져오기
            current_default = None
            if 'default' in profiles:
                current_default = 'default'

            # 현재 default 프로필이 있으면 표시
            if current_default:
                click.echo(f"현재 기본 프로필: {current_default}")

            # 사용자가 프로필 선택
            selected_profile = select_from_list(profiles, "AWS 프로필 선택")

            if selected_profile:
                if selected_profile == 'default':
                    click.echo("이미 기본 프로필입니다.")
                    return

                # 선택된 프로필의 자격 증명 가져오기
                aws_access_key_id = config[selected_profile].get('aws_access_key_id', '')
                aws_secret_access_key = config[selected_profile].get('aws_secret_access_key', '')
                aws_session_token = config[selected_profile].get('aws_session_token', '')

                # credentials 파일을 직접 수정하여 default 프로필 설정
                if 'default' not in config:
                    config.add_section('default')

                config['default']['aws_access_key_id'] = aws_access_key_id
                config['default']['aws_secret_access_key'] = aws_secret_access_key

                # 세션 토큰이 있는 경우 설정
                if aws_session_token:
                    config['default']['aws_session_token'] = aws_session_token
                elif 'aws_session_token' in config['default']:
                    # 세션 토큰이 없는 프로필로 변경하는 경우, 기존 토큰 제거
                    config.remove_option('default', 'aws_session_token')

                # 변경사항을 파일에 저장
                with open(credentials_path, 'w') as configfile:
                    config.write(configfile)

                click.echo(f"'{selected_profile}' 프로필을 기본(default) 프로필로 설정했습니다.")
            else:
                click.echo("프로필이 선택되지 않았습니다.")
        except Exception as e:
            click.echo(f"AWS 프로필 관리 중 오류 발생: {e}")
